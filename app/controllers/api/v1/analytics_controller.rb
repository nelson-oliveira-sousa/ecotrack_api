module Api
  module V1
    class AnalyticsController < ApiController
      # GET /api/v1/dashboard/summary
      def summary
        tenant_id = Current.tenant.id
        cache_key = "dashboard_summary_tenant_#{tenant_id}"

        summary_data = Rails.cache.fetch(cache_key, expires_in: 60.seconds) do
          # Agora aponta para o domínio correto
          Dashboard::Services::SummaryService.call(tenant: Current.tenant)
        end

        render json: summary_data, status: :ok
      end
    end
  end
end
