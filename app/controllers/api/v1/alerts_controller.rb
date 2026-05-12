# app/controllers/api/v1/alerts_controller.rb
module Api
  module V1
    class AlertsController < Api::V1::ApiController
      include ActionController::Live

      # GET /api/v1/alerts
      def index
        alerts = Current.tenant.alerts.order(created_at: :desc)

        # Utiliza o Serializer para manter o formato padronizado
        data = Alerts::Serializers::AlertSerializer.render_collection(alerts)

        render_result(Result.new(success: true, data: data))
      end

      # GET /api/v1/alerts/stream
      def stream
        response.headers["Content-Type"] = "text/event-stream"
        response.headers["Last-Modified"] = Time.now.httpdate
        response.headers["Cache-Control"] = "no-cache"
        response.headers["X-Accel-Buffering"] = "no"

        channel = "alerts_tenant_#{Current.tenant.id}"

        # Delega a ligação persistente para o Adaptador
        Stream::PostgresClient.listen(channel: channel, stream: response.stream)
      end

      # PATCH/PUT /api/v1/alerts/:id/resolve
      def resolve
        result = Alerts::Services::ResolveAlert.call(
          tenant: Current.tenant,
          alert_id: params[:id]
        )

        render_result(result)
      end
    end
  end
end
