module Telemetry
  module Services
    module ProcessMessage
      def self.call(message_id)
        message = MqttMessage.find(message_id)

        unless message
          Rails.logger.error("❌ MqttMessage com ID #{message_id} não encontrado.")
          return nil
        end

        payload = JSON.parse(message.payload).symbolize_keys

        reading_data = mount_reading_data(payload)

        Waste::Services::UpdateBinStatusService.call(reading_data)

        message.update!(processed_at: Time.zone.now, status: :processed)
      rescue => e
        message.update!(status: :failed, error_log: e.message)
        raise e
      end

      private

      def mount_reading_data(payload)
        {
          bin_id: payload[:bin_id],
          level: payload[:level].to_f,
          timestamp: Time.zone.now
        }
      end
    end
  end
end
