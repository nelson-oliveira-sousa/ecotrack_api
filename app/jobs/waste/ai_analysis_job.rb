module Waste
  class AiAnalysisJob < ApplicationJob
    queue_as :default

    def perform(bin_id)
      bin = Waste::Bin.find(bin_id)

      # Throttle: Não vamos gastar API se analisamos há menos de 30 min
      return if bin.last_analysis_at.present? && bin.last_analysis_at > 30.minutes.ago

      Waste::Services::AnalyzeBinService.call(bin)
    end
  end
end
