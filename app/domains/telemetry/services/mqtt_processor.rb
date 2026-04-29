# app/domains/telemetry/mqtt_processor.rb
module Telemetry
  class MqttProcessor
    def initialize
      @buffer = []
      @mutex = Mutex.new
      @last_flush = Time.current
      start_watchdog
    end

    def handle(topic, message)
      payload = JSON.parse(message).symbolize_keys

      # Extrai o sensor_id do payload (ex: {"sensor_id": "ESP32-1", "level": 80}) ou do tópico
      sensor_identifier = payload[:sensor_id] || topic.split("/")[1]

      # Procura a lixeira utilizando a nova coluna sensor_id
      bin = Waste::Bin.find_by(sensor_id: sensor_identifier)

      unless bin
        Rails.logger.warn "⚠️ Mensagem ignorada: Lixeira com sensor '#{sensor_identifier}' não encontrada."
        return
      end

      @mutex.synchronize do
        @buffer << build_message_hash(bin, payload, topic)
      end

      flush_if_needed
    rescue JSON::ParserError
      Rails.logger.error "🗑️ Payload inválido recebido de #{topic}"
    ensure
      Current.reset # Evita vazamento de contexto (Multi-tenancy)
    end

    def flush!
      @mutex.synchronize do
        return if @buffer.empty?

        # Persistência atómica via insert_all para suportar alta carga
        MqttMessage.insert_all(@buffer, unique_by: :event_id)

        # Dispara processamento assíncrono para as lixeiras
        MqttBatchProcessorJob.perform_later

        @buffer.clear
        @last_flush = Time.current
      end
    end

    private

    def build_message_hash(bin, payload, topic)
      {
        tenant_id: bin.tenant_id,
        event_id: payload[:id] || SecureRandom.uuid,
        topic: topic,
        payload: payload,
        status: "new",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    def flush_if_needed
      batch_size = ENV.fetch("MQTT_DB_BATCH_SIZE", 10).to_i
      flush! if @buffer.size >= batch_size
    end

    def start_watchdog
      Thread.new do
        loop do
          sleep 1
          max_wait = ENV.fetch("MQTT_DB_MAX_WAIT", 5).to_i
          flush! if (Time.current - @last_flush) >= max_wait && @buffer.any?
        end
      end
    end
  end
end
