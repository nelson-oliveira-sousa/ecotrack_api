# app/adapters/mqtt/client.rb
require "mqtt"

module Mqtt
  class Client
    def initialize
      @config = build_config
    end

    def subscribe(topic)
      Rails.logger.info "📡 Conectando ao HiveMQ em #{@config[:host]}..."

      MQTT::Client.connect(@config) do |client|
        client.subscribe(topic)
        client.get do |topic, message|
          # Repassa para o bloco que chamou o subscribe
          yield(topic, message) if block_given?
        end
      end
    rescue => e
      Rails.logger.error "🔥 Erro no Adapter MQTT: #{e.message}"
      sleep 5 # Backoff simples antes de tentar reconectar
      retry
    end

    private

    def build_config
      {
        host: ENV.fetch("MQTT_HOST", "localhost"),
        port: ENV.fetch("MQTT_PORT", 8883).to_i,
        username: ENV["MQTT_USER"],
        password: ENV["MQTT_PASSWORD"],
        ssl: ENV.fetch("MQTT_SSL", "false").downcase == "true"
      }
    end
  end
end
