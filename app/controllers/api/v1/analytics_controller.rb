module Api
  module V1
    class AnalyticsController < ApiController
      # GET /api/v1/dashboard/summary
      def summary
        # O Controller delega TUDO para o Service.
        # Ele não sabe mais o que é cache.
        result = Dashboard::Services::SummaryService.call(tenant: Current.tenant)

        render_result(result)
      end
    end
  end
end
