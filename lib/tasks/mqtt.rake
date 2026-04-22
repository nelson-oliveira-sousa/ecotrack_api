namespace :mqtt do
  desc "Listener MQTT Enterprise - Modelo Unificado (ID no Body)"
  task listen: :environment do
    require "mqtt"
    require "digest"

    # 1. CONFIGURAÇÕES
    mqtt_host  = ENV.fetch("MQTT_HOST", "localhost")
    mqtt_port  = ENV.fetch("MQTT_PORT", 8883).to_i
    mqtt_user  = ENV["MQTT_USER"]
    mqtt_pass  = ENV["MQTT_PASSWORD"]

    # AJUSTE: Ouve 'telemetry/QUALQUER_TENANT/bins'
    # O '+' é o coringa para o código da prefeitura
    topic = ENV.fetch("MQTT_TOPIC", "telemetry/+/bins")

    running = true
    Rails.logger = Logger.new($stdout)
    Rails.logger.info("📡 Iniciando MQTT Listener (SaaS Mode) - Tópico: #{topic}")

    client_id = ENV.fetch("MQTT_CLIENT_ID") { "ecotrack_#{Rails.env}_#{Socket.gethostname}" }

    client = MQTT::Client.new(
      host: mqtt_host,
      port: mqtt_port,
      username: mqtt_user,
      password: mqtt_pass,
      ssl: mqtt_port == 8883,
      client_id: client_id
    )
    client.clean_session = false

    # 2. SHUTDOWN SEGURO
    %w[INT TERM].each do |signal|
      trap(signal) do
        Rails.logger.warn("🛑 Encerrando Listener MQTT graciosamente...")
        running = false
        exit(0)
      end
    end

    # 3. LÓGICA DE BUFFER (PERFORMANCE)
    insert_buffer = []
    last_flush = Time.current
    BATCH_INSERT_SIZE = ENV.fetch("MQTT_DB_BATCH_SIZE", 10).to_i # Lote de 10 para testes rápidos
    MAX_WAIT = ENV.fetch("MQTT_DB_MAX_WAIT", 2).to_i

    flush_to_db = lambda do |reason|
      return if insert_buffer.empty?

      begin
        # Insere em massa ignorando duplicatas (Idempotência)
        MqttMessage.insert_all(insert_buffer, unique_by: :event_id)

        # 🔥 GATILHO: Notifica o Solid Queue que há trabalho novo
        MqttBatchProcessorJob.perform_later

        Rails.logger.info("📦 Flush DB (#{reason}) - #{insert_buffer.size} msgs persistidas.")
        insert_buffer.clear
        last_flush = Time.current
      rescue StandardError => e
        Rails.logger.error("💥 Erro ao salvar no banco: #{e.message}")
      end
    end

    # Thread de Vigilância (Timeout)
    Thread.new do
      loop do
        sleep 1
        break unless running
        if insert_buffer.any? && (Time.current - last_flush) >= MAX_WAIT
          flush_to_db.call("timeout")
        end
      end
    end

    # 4. LOOP DE LEITURA
    while running
      begin
        unless client.connected?
          client.connect
          client.subscribe(topic, 1) # QoS 1 garante a entrega
          Rails.logger.info("✅ Conectado ao HiveMQ!")
        end

        client.get do |received_topic, message|
          begin
            payload = JSON.parse(message)

            # Idempotência: Gera ID único baseado no conteúdo se não houver um no JSON
            event_id = payload["id"] || Digest::SHA256.hexdigest("#{received_topic}-#{message}-#{Time.current.to_f}")

            insert_buffer << {
              event_id: event_id,
              topic: received_topic,
              payload: payload, # Aqui o Rails salva o JSON completo (incluindo o bin_id)
              status: "new",
              retry_count: 0,
              created_at: Time.current,
              updated_at: Time.current
            }

            flush_to_db.call("batch_size") if insert_buffer.size >= BATCH_INSERT_SIZE

          rescue JSON::ParserError
            Rails.logger.error("🗑️ JSON inválido em #{received_topic}")
          end
        end
      rescue StandardError => e
        Rails.logger.error("🔥 Erro na conexão: #{e.message}. Reconectando em 5s...")
        sleep 5
      end
    end
  end
end
