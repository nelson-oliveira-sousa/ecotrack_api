module Waste
  module Services
    class RecordReading < ApplicationService
      def initialize(bin:, level:, battery: nil, raw_payload: nil)
        @bin = bin
        @level = level
        @battery = battery
        @raw_payload = raw_payload
      end

      def call
        return failure("Lixeira não encontrada.", :not_found) unless @bin
        return failure("Nível é obrigatório.", :bad_request) if @level.blank?

        normalized_level = @level.to_i
        normalized_battery = @battery.presence || @bin.battery

        ActiveRecord::Base.transaction do
          @bin.update!(level: normalized_level, battery: normalized_battery)

          @bin.readings.create!(
            level: @bin.level,
            status: @bin.status,
            battery: @bin.battery
          )

          create_raw_reading if @raw_payload.present?
        end

        Waste::AiAnalysisJob.perform_later(@bin.id) if @bin.analysis_needed?

        success({ bin: @bin })
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages, :unprocessable_entity)
      rescue StandardError => e
        failure("Erro ao registrar leitura: #{e.message}", :internal_server_error)
      end

      private

      def create_raw_reading
        Telemetry::RawReading.create!(
          waste_bin: @bin,
          level: @bin.level,
          raw_payload: @raw_payload
        )
      end
    end
  end
end
