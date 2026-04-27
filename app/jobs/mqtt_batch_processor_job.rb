class MqttBatchProcessorJob < ApplicationJob
  queue_as :default

  # Mantemos a concorrência limitada para garantir a ordem das leituras
  limits_concurrency to: 1, key: "mqtt_batch_processor", duration: 5.minutes

  def perform
    # Busca mensagens pendentes (status: :new)
    messages = MqttMessage.status_new.limit(100)

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

    # 1. Extração no padrão ChirpStack
    dev_eui   = payload.dig("deviceInfo", "devEui")
    telemetry = payload["object"] || {}

    new_level     = telemetry["level"]
    battery_level = telemetry["battery"] || 100

    # 2. Busca a lixeira pelo Identificador Global (dev_eui)
    # Aqui o tenant já vem "de brinde" pela associação
    bin = Waste::Bin.find_by!(dev_eui: dev_eui)

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
    msg.update!(status: :failed, error_log: "DevEUI #{dev_eui} não encontrado")
    Rails.logger.error "❌ Dispositivo #{dev_eui} não cadastrado."
  rescue => e
    msg.update!(status: :failed, error_log: e.message)
    Rails.logger.error "❌ Erro no processamento: #{e.message}"
  end
end
