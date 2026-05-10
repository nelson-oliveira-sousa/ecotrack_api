class MqttBatchProcessorJob < ApplicationJob
  queue_as :default

  # Mantemos a concorrência limitada para garantir a ordem das leituras
  limits_concurrency to: 1, key: "mqtt_batch_processor", duration: 5.minutes

  def perform
    messages = MqttMessage.ready_for_processing.limit(100)

    return if messages.empty?

    messages.each do |msg|
      process_message(msg)
    end

    # Recursão para limpar a fila se houver muito volume
    MqttBatchProcessorJob.perform_later if MqttMessage.status_new.any?
  end

  private

  def process_message(msg)
    msg.status_processing!
    payload = msg.payload

    dev_eui = payload.dig("deviceInfo", "devEui")
    sensor_id = payload["sensor_id"] || payload["sensorId"] || dev_eui
    telemetry = payload["object"] || {}

    new_level = telemetry["level"] || payload["level"]
    battery_level = telemetry["battery"] || payload["battery"] || 100

    bin = Waste::Bin.find_by!(sensor_id: sensor_id)

    # 🔥 ATUALIZAÇÃO SÊNIOR: Transação Atômica
    ActiveRecord::Base.transaction do
      # Atualiza o estado atual da lixeira
      bin.update!(level: new_level, battery: battery_level)

      # Cria o registro histórico para os gráficos e IA
      bin.readings.create!(
        level: new_level,
        status: bin.status,
        battery: battery_level
      )

      # Dispara a IA apenas se necessário
      if bin.analysis_needed?
        Waste::AiAnalysisJob.perform_later(bin.id)
      end
    end

    msg.update!(status: :processed, processed_at: Time.current)

  rescue ActiveRecord::RecordNotFound
    msg.update!(status: :failed)
    Rails.logger.error("Dispositivo #{sensor_id || dev_eui} não cadastrado.")
  rescue => e
    msg.update!(status: :failed)
    Rails.logger.error("Erro no processamento MQTT #{msg.id}: #{e.message}")
  end
end
