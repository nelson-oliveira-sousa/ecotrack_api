# app/domains/alerts/services/resolve_alert.rb
module Alerts
  module Services
    class ResolveAlert < ApplicationService
      def initialize(tenant:, alert_id:)
        @tenant = tenant
        @alert_id = alert_id
      end

      def call
        # 1. Blindagem multi-tenant imediata
        alert = @tenant.alerts.find_by(id: @alert_id)

        return failure("Alerta não encontrado.", :not_found) unless alert

        # 2. Idempotência: Devolve sucesso mesmo se já estiver resolvido,
        # sem quebrar o cliente que tentou duas vezes.
        if alert.resolved?
          return success(payload_format(alert, "Este alerta já foi resolvido e retirado da fila."))
        end

        # 3. Execução da Ação
        if alert.update(status: :resolved)
          success(payload_format(alert, "Alerta resolvido com sucesso."))
        else
          failure(alert.errors.full_messages, :unprocessable_entity)
        end
      rescue StandardError => e
        failure("Erro ao processar a resolução do alerta: #{e.message}", :internal_server_error)
      end

      private

      # Helper para não repetir o mesmo formato de saída nas duas condições de sucesso
      def payload_format(alert, message)
        {
          message: message,
          alert: {
            id: alert.id,
            status: alert.status,
            resolved_at: alert.updated_at
          }
        }
      end
    end
  end
end
