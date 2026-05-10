module Telemetry
  module Services
    class IngestReading < ApplicationService
      def initialize(sensor_id: nil, level: nil, battery: nil, raw_payload: {}, tenant: nil, valid_data: nil)
        data = valid_data || {}

        @sensor_id = sensor_id || data[:sensor_id]
        @level = level || data[:level]
        @battery = battery || data[:battery]
        @raw_payload = raw_payload.presence || data
        @tenant = tenant
      end

      def call
        contract_result = Telemetry::Contracts::IngestContract.new.call(
          sensor_id: @sensor_id,
          level: @level,
          battery: @battery
        )

        return failure(contract_result.errors.to_h, :unprocessable_entity) unless contract_result.success?

        bin = bin_scope.find_by(sensor_id: @sensor_id)
        return failure("Lixeira com sensor #{@sensor_id} não encontrada.", :not_found) unless bin

        Waste::Services::RecordReading.call(
          bin: bin,
          level: @level,
          battery: @battery,
          raw_payload: @raw_payload
        )
      end

      private

      def bin_scope
        @tenant ? @tenant.waste_bins : Waste::Bin.all
      end
    end
  end
end
