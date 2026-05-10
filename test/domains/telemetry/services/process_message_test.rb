require "test_helper"

module Telemetry
  module Services
    class ProcessMessageTest < ActiveSupport::TestCase
      test "processa mensagem MQTT valida e registra leitura" do
        bin = waste_bins(:one)
        message = MqttMessage.create!(
          tenant: bin.tenant,
          event_id: SecureRandom.uuid,
          topic: "application/1/device/#{bin.sensor_id}/rx",
          payload: {
            "deviceInfo" => { "devEui" => bin.sensor_id },
            "object" => { "level" => 82, "battery" => 91 }
          },
          status: :new
        )

        result = Telemetry::Services::ProcessMessage.call(message: message)

        assert result.success?
        assert_equal "processed", message.reload.status
        assert_equal 82, bin.reload.level
        assert_equal 91, bin.battery
        assert_equal 1, bin.readings.where(level: 82, battery: 91).count
      end

      test "marca mensagem como failed quando sensor nao existe" do
        message = MqttMessage.create!(
          tenant: tenants(:one),
          event_id: SecureRandom.uuid,
          topic: "application/1/device/UNKNOWN/rx",
          payload: {
            "deviceInfo" => { "devEui" => "UNKNOWN" },
            "object" => { "level" => 82, "battery" => 91 }
          },
          status: :new
        )

        result = Telemetry::Services::ProcessMessage.call(message: message)

        assert result.failure?
        assert_equal :not_found, result.status
        assert_equal "failed", message.reload.status
      end
    end
  end
end
