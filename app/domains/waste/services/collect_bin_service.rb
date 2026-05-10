# app/domains/waste/services/collect_bin_service.rb
module Waste
  module Services
    class CollectBinService < ApplicationService
      def initialize(bin:, collected_at: nil)
        @bin = bin
        @collected_at = collected_at
      end

      def call
        ActiveRecord::Base.transaction do
          @bin.update!(level: 0, status: "collected")
          @bin.readings.create!(
            level: 0,
            status: "collected",
            battery: @bin.battery,
            created_at: @collected_at.presence || Time.current
          )
        end

        success({ bin: @bin })
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages, :unprocessable_entity)
      end
    end
  end
end
