module Telemetry
  module Contracts
    class IngestContract < Dry::Validation::Contract
      params do
        required(:tenant_slug).filled(:string)
        required(:bin_label).filled(:string)
        required(:level).filled(:integer, gteq?: 0, lteq?: 100)
        optional(:battery).maybe(:integer, gteq?: 0, lteq?: 100)
      end
    end
  end
end
