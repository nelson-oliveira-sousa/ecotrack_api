# app/domains/telemetry/services/mqtt_runner.rb
module Telemetry
  module Services
    class MqttRunner
      def self.start
        processor = Telemetry::Services::MqttProcessor.new
        client = Mqtt::Client.new
        topic = ENV.fetch("MQTT_TOPIC", "telemetry/+/bins")

        Rails.logger.info("Conectando ao broker MQTT")
        Rails.logger.info("Tópico MQTT assinado: #{topic}")

        client.subscribe(topic) do |received_topic, message|
          processor.handle(received_topic, message)
        end
      rescue Interrupt
        Rails.logger.info("Encerrando worker MQTT")
        processor&.flush!
        exit(0)
      rescue => e
        Rails.logger.fatal("Erro fatal no worker MQTT: #{e.message}\n#{e.backtrace.join("\n")}")
        exit(1)
      end
    end
  end
end
