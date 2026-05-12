# app/domains/alerts/services/create_alert.rb
module Alerts
  module Services
    class CreateAlert < ApplicationService
      def initialize(tenant:, category:, severity:, title:, message:, alertable: nil)
        @tenant = tenant
        @category = category
        @severity = severity
        @title = title
        @message = message
        @alertable = alertable
      end

      def call
        alert = build_alert

        if alert.save
          broadcast_to_stream(alert)
          Result.new(success: true, data: Alerts::Serializers::AlertSerializer.render(alert), status: :created)
        else
          Result.new(success: false, error: alert.errors.full_messages, status: :unprocessable_entity)
        end
      rescue StandardError => e
        Rails.logger.error("[Alerts::CreateAlert] Falha ao criar alerta: #{e.message}")
        Result.new(success: false, error: "Erro interno ao processar alerta", status: :internal_server_error)
      end

      private

      def build_alert
        Alert.new(
          tenant: @tenant,
          category: @category,
          severity: @severity,
          title: @title,
          message: @message,
          alertable: @alertable,
          status: :pending
        )
      end

      def broadcast_to_stream(alert)
        channel = "alerts_tenant_#{alert.tenant_id}"

        payload = {
          success: true,
          action: "ALERT_CREATED",
          data: Alerts::Serializers::AlertSerializer.render(alert)
        }

        Stream::PostgresClient.broadcast(channel: channel, payload: payload)
      end
    end
  end
end
