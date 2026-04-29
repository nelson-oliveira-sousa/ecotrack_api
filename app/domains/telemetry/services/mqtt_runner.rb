# app/domains/telemetry/services/mqtt_runner.rb
module Telemetry
  module Services
    class MqttRunner
      def self.start
        # 1. Inicializa o processador (Lógica de Domínio)
        processor = Telemetry::Services::MqttProcessor.new

        # 2. Inicializa o Client (Adapter de Infraestrutura)
        client = Mqtt::Client.new
        topic = ENV.fetch("MQTT_TOPIC", "telemetry/+/bins")

        puts "📡 Conectando ao HiveMQ..."
        puts "📝 Tópico assinado: #{topic}"

        # 3. Inicia o loop de escuta passando o bloco
        client.subscribe(topic) do |received_topic, message|
          processor.handle(received_topic, message)
        end
      rescue Interrupt
        puts "\n🛑 Encerrando worker de forma graciosa..."
        processor&.flush! # Garante o flush final de segurança (o & previne erros caso processor seja nil)
        exit(0)
      rescue => e
        Rails.logger.fatal "🔥 Erro fatal no Worker: #{e.message}\n#{e.backtrace.join("\n")}"
        exit(1)
      end
    end
  end
end
