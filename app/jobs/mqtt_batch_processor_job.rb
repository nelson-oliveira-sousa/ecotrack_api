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
    result = Telemetry::Services::ProcessMessage.call(message: msg)

    if result.success?
      message.update!(status: "processed", last_error: nil)
    else
      message.update!(status: "failed", last_error: result.error)
    end

  rescue StandardError => e
    Rails.logger.error("Exceção no processamento MQTT #{msg.id}: #{e.class} - #{e.message}")
    message.update!(
      status: "failed",
      last_error: "#{e.class}: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
    )
  end
end
