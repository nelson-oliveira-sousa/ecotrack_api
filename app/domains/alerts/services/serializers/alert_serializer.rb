# app/domains/alerts/serializers/alert_serializer.rb
module Alerts
  module Serializers
    class AlertSerializer
      def self.render(alert)
        return nil unless alert

        {
          id: alert.id,
          category: alert.category,
          severity: alert.severity,
          status: alert.status,
          title: alert.title,
          message: alert.message,
          created_at: alert.created_at,
          updated_at: alert.updated_at
        }
      end

      def self.render_as_hash(resource)
        resource.respond_to?(:map) ? render_collection(resource) : render(resource)
      end

      def self.render_collection(alerts)
        alerts.map { |alert| render(alert) }
      end

      def self.render_errors(alert)
        { success: false, error: alert.errors.full_messages }
      end
    end
  end
end
