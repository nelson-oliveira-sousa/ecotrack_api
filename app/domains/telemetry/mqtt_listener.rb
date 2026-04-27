require "mqtt"
require "digest"

module Telemetry
  class MqttListener
    def initialize
      @mqtt_config = {
        host: ENV.fetch("MQTT_HOST", "localhost"),
        port: ENV.fetch("MQTT_PORT", 8883).to_i,
        username: ENV["MQTT_USER"],
        password: ENV["MQTT_PASSWORD"],
        ssl: ENV.fetch("MQTT_PORT", "8883") == "8883"
      }
      @insert_buffer = []
      @mutex = Mutex.new
      @last_flush = Time.current
      @running = true
    end

    def start
      setup_traps
      start_watchdog

      Rails.logger.info "📡 Conectando ao HiveMQ em #{@mqtt_config[:host]}..."

      MQTT::Client.connect(@mqtt_config) do |client|
        # Ouve todos os dispositivos: telemetry/CODIGO_TENANT/bins
        client.subscribe(ENV.fetch("MQTT_TOPIC", "topico/meu_topico"), 1)

        while @running
          client.get do |topic, message|
            handle_message(topic, message)
          end
        end
      end
    rescue => e
      Rails.logger.error "🔥 Falha crítica no Listener: #{e.message}"
      sleep 5
      retry if @running
    end

    private

    def handle_message(topic, message)
      begin
        payload = JSON.parse(message)

        # 1. No ChirpStack, o identificador único do sensor (devEui)
        # vem dentro do nó deviceInfo.
        dev_eui = payload.dig("deviceInfo", "devEui")

        # 2. Buscamos a lixeira pelo dev_eui que configuramos na migration.
        # Isso elimina a necessidade de hardcode ou de extrair código do tópico.
        bin = Waste::Bin.find_by(dev_eui: dev_eui)

        unless bin
          Rails.logger.warn "⚠️ Mensagem ignorada: Dispositivo LoRaWAN '#{dev_eui}' não cadastrado."
          return
        end

        # 3. O Tenant agora é dinâmico! Ele vem da lixeira encontrada.
        tenant = bin.tenant
        Current.tenant = tenant

        @mutex.synchronize do
          # Mantemos sua lógica de buffer de alta performance
          @insert_buffer << build_message_hash(topic, payload, tenant.id)
        end

        flush_if_needed
      rescue JSON::ParserError
        Rails.logger.error "🗑️ Payload inválido recebido de #{topic}"
      rescue => e
        Rails.logger.error "🔥 Erro ao processar mensagem do ChirpStack: #{e.message}"
      ensure
        # Limpa o contexto para a próxima mensagem do loop (essencial para concorrência)
        Current.reset
      end
    end

    def build_message_hash(topic, payload, tenant_id)
      {
        tenant_id: tenant_id,
        event_id: payload["id"] || Digest::SHA256.hexdigest("#{topic}-#{payload}-#{Time.current.to_f}"),
        topic: topic,
        payload: payload,
        status: "new",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    def flush_if_needed
      batch_size = ENV.fetch("MQTT_DB_BATCH_SIZE", 10).to_i
      flush! if @insert_buffer.size >= batch_size
    end

    def flush!
      @mutex.synchronize do
        return if @insert_buffer.empty?

        # Persistência atômica e ultra rápida no PostgreSQL
        MqttMessage.insert_all(@insert_buffer, unique_by: :event_id)

        # Dispara o Job de processamento.
        # O Job herdará o Current.tenant_id automaticamente!
        MqttBatchProcessorJob.perform_later

        Rails.logger.info "📦 Batch flush: #{@insert_buffer.size} mensagens processadas."

        @insert_buffer.clear
        @last_flush = Time.current
      end
    end

    def start_watchdog
      # Garante que as mensagens não fiquem "presas" no buffer se o volume for baixo
      Thread.new do
        while @running
          sleep 1
          max_wait = ENV.fetch("MQTT_DB_MAX_WAIT", 5).to_i
          flush! if (Time.current - @last_flush) >= max_wait && @insert_buffer.any?
        end
      end
    end

    def setup_traps
      %w[INT TERM].each do |sig|
        trap(sig) do
          @running = false
          flush!
          exit(0)
        end
      end
    end
  end
end
