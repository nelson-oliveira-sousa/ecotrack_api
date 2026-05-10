module Telemetry
  module Contracts
    class IngestContract < Dry::Validation::Contract
      params do
        required(:sensor_id).filled(:string)
        required(:level).filled(:integer, gteq?: 0, lteq?: 100)
        optional(:battery).maybe(:integer, gteq?: 0, lteq?: 100)
      end
    end
  end
end
