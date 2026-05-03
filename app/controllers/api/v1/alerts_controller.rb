# app/controllers/api/v1/alerts_controller.rb
module Api
  module V1
    class AlertsController < Api::V1::ApiController
      include ActionController::Live

      # GET /api/v1/alerts/stream
      def stream
        # ⚡ SSE: Mantemos a infraestrutura crua do Rack/Puma.
        # Não utilizamos render_result aqui pois a conexão não fecha.
        response.headers["Content-Type"] = "text/event-stream"
        response.headers["Last-Modified"] = Time.now.httpdate
        response.headers["Cache-Control"] = "no-cache"
        response.headers["X-Accel-Buffering"] = "no"

        channel = "alerts_tenant_#{Current.tenant.id}"

        ActiveRecord::Base.connection_pool.with_connection do |connection|
          connection.execute("LISTEN #{channel}")

          begin
            loop do
              connection.raw_connection.wait_for_notify(5) do |event, pid, payload|
                response.stream.write("data: #{payload}\n\n")
              end
              response.stream.write(":\n\n")
            end
          rescue IOError, ActionController::Live::ClientDisconnected
            Rails.logger.info "Conexão SSE do Tenant #{Current.tenant.id} fechada."
          ensure
            connection.execute("UNLISTEN #{channel}")
            response.stream.close
          end
        end
      end

      # PATCH/PUT /api/v1/alerts/:id/resolve
      def resolve
        # O Controller delega a verificação de existência, idempotência e update
        # para a camada de domínio (Service).
        result = Alerts::Services::ResolveAlert.call(
          tenant: Current.tenant,
          alert_id: params[:id]
        )

        render_result(result)
      end
    end
  end
end
