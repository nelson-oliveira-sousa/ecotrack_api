# lib/tasks/mqtt.rake
namespace :mqtt do
  desc "Listener MQTT Enterprise para SaaS (Auto-reconnect, Micro-batching, QoS 1, Heartbeat)"
  task listen: :environment do
    require "mqtt"

    # 1. CONFIGURAÇÕES DINÂMICAS VIA .ENV (SaaS não hardcoda configuração)
    mqtt_host  = ENV.fetch("MQTT_HOST", "localhost")
    topic      = ENV.fetch("MQTT_TOPIC", "ecotrack/+/telemetry") # Usando curinga (+) para o futuro
    batch_size = ENV.fetch("MQTT_BATCH_SIZE", 50).to_i
    max_wait   = ENV.fetch("MQTT_MAX_WAIT_SECONDS", 5).to_i

    buffer = []
    last_flush = Time.current
    mutex = Mutex.new
    running = true # Flag de controle de vida do processo

    Rails.logger = Logger.new($stdout) # Força o log pro console do Docker
    Rails.logger.info("📡 Iniciando MQTT Listener [SaaS Mode] - Host: #{mqtt_host}")

    # 2. O CAMINHÃO DE LIXO (DESPACHO)
    dispatch_batch = ->(reason) do
      batch_to_send = []

      mutex.synchronize do
        return if buffer.empty?
        batch_to_send = buffer.dup
        buffer.clear
        last_flush = Time.current
      end

      # O ActiveJob assume daqui. Se o Postgres estiver fora, o Solid Queue segura a bronca.
      Telemetry::ProcessBatchJob.perform_later(batch_to_send)
      Rails.logger.info("📦 Lote de #{batch_to_send.size} msgs despachado. Motivo: #{reason}")
    end

    # 3. GRACEFUL SHUTDOWN
    %w[INT TERM].each do |signal|
      trap(signal) do
        Rails.logger.warn("🛑 Recebido sinal #{signal}. Iniciando Desligamento Elegante...")
        running = false # Avisa a thread principal para parar de tentar reconectar
        dispatch_batch.call("Shutdown")
        exit(0)
      end
    end

    # 4. O CRONÔMETRO DE EMERGÊNCIA E HEARTBEAT
    Thread.new do
      loop do
        sleep 1
        break unless running

        # Verifica se precisa fechar o lote por tempo
        if (Time.current - last_flush) >= max_wait
          dispatch_batch.call("Timeout (#{max_wait}s)")
        end

        # HEARTBEAT: Avisa a infraestrutura que este processo não travou (Deadlock)
        # O Docker/K8s pode checar esse arquivo para saber se precisa matar e reiniciar o container
        File.write(Rails.root.join("tmp/mqtt_heartbeat.txt"), Time.current.to_s)
      end
    end

    # 5. LOOP DE AUTO-RECONNECT (O Motor Inquebrável)
    client = MQTT::Client.new(mqtt_host)
    client.clean_session = false # Ajuda a não perder msgs no QoS 1 se a conexão cair rápido

    while running
      begin
        unless client.connected?
          Rails.logger.info("🔄 Conectando ao broker MQTT...")
          client.connect
          # Assina o tópico exigindo QoS 1 (Garante a entrega)
          client.subscribe(topic, 1)
          Rails.logger.info("✅ Conectado e escutando: #{topic}")
        end

        # client.get bloqueia a thread esperando mensagens
        client.get do |received_topic, message|
          begin
            payload = JSON.parse(message).deep_symbolize_keys

            mutex.synchronize { buffer << payload }

            dispatch_batch.call("Lote Cheio") if buffer.size >= batch_size
          rescue JSON::ParserError
            Rails.logger.error("🗑️ JSON Inválido no tópico #{received_topic}: #{message}")
          end
        end

      rescue SocketError, Timeout::Error, MQTT::ProtocolException, Errno::ECONNREFUSED => e
        # Se o Mosquitto cair, a task NÃO MORRE. Ela cai aqui, espera 5 segundos e tenta de novo.
        Rails.logger.error("🔥 Queda de conexão MQTT: #{e.message}. Tentando reconectar em 5s...")

        # Avisa o Sentry/Rollbar (Descomente quando tiver conta lá)
        # Sentry.capture_exception(e)

        sleep 5
      rescue StandardError => e
        Rails.logger.fatal("💥 Erro fatal desconhecido: #{e.message}")
        sleep 5 # Previne um loop infinito de consumo de CPU de 100%
      end
    end
  end
end
