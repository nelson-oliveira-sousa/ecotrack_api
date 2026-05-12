# app/domains/alerts/services/resolve_alert.rb
module Alerts
  module Services
    class ResolveAlert < ApplicationService
      def initialize(tenant:, alert_id:)
        @tenant = tenant
        @alert_id = alert_id
      end

      def call
        alert = @tenant.alerts.find_by(id: @alert_id)

        return Result.new(success: false, error: "Alerta não encontrado.", status: :not_found) unless alert
        return Result.new(success: true, data: Alerts::Serializers::AlertSerializer.render(alert), status: :ok) if alert.resolved?

        if alert.update(status: :resolved)
          broadcast_resolved(alert)
          Result.new(success: true, data: Alerts::Serializers::AlertSerializer.render(alert), status: :ok)
        else
          Result.new(success: false, error: alert.errors.full_messages, status: :unprocessable_entity)
        end
      end

      private

      def broadcast_resolved(alert)
        channel = "alerts_tenant_#{alert.tenant_id}"

        payload = {
          success: true,
          action: "ALERT_RESOLVED",
          data: Alerts::Serializers::AlertSerializer.render(alert)
        }

        Stream::PostgresClient.broadcast(channel: channel, payload: payload)
      end
    end
  end
end
