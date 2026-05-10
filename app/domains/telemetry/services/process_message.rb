module Telemetry
  module Services
    class ProcessMessage < ApplicationService
      def initialize(message: nil, message_id: nil)
        @message = message || MqttMessage.find_by(id: message_id)
      end

      def call
        return failure("Mensagem MQTT não encontrada.", :not_found) unless @message

        @message.status_processing!

        result = Telemetry::Services::IngestReading.call(
          sensor_id: sensor_id,
          level: level,
          battery: battery,
          raw_payload: payload,
          tenant: @message.tenant
        )

        if result.success?
          @message.update!(status: :processed, processed_at: Time.current)
          success({ message: @message, bin: result.data[:bin] })
        else
          @message.update!(status: :failed)
          result
        end
      rescue StandardError => e
        @message&.update!(status: :failed)
        failure("Erro ao processar mensagem MQTT: #{e.message}", :internal_server_error)
      end

      private

      def payload
        @payload ||= @message.payload || {}
      end

      def sensor_id
        payload["sensor_id"] || payload["sensorId"] || payload.dig("deviceInfo", "devEui")
      end

      def telemetry
        payload["object"] || {}
      end

      def level
        telemetry["level"] || payload["level"]
      end

      def battery
        telemetry["battery"] || payload["battery"]
      end
    end
  end
end
