# app/controllers/api/v1/alerts_controller.rb
module Api
  module V1
    class AlertsController < Api::V1::ApiController
      include ActionController::Live

      def stream
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

      def resolve
        # 1. Busca o alerta blindando pelo Tenant (Prefeitura)
        alert = Current.tenant.alerts.find_by(id: params[:id])

        # 2. Se um hacker tentar passar o ID de outra prefeitura, ou não existir
        if alert.nil?
          return render json: { error: "Alerta não encontrado." }, status: :not_found
        end

        # 3. Idempotência: Se já foi resolvido, devolve sucesso mesmo assim
        if alert.resolved?
          return render json: { message: "Este alerta já foi resolvido e retirado da fila." }, status: :ok
        end

        # 4. Atualiza e salva
        if alert.update(status: :resolved)
          render json: {
            message: "Alerta resolvido com sucesso.",
            alert: {
              id: alert.id,
              status: alert.status,
              resolved_at: alert.updated_at
            }
          }, status: :ok
        else
          render json: { error: "Falha ao resolver alerta.", details: alert.errors }, status: :unprocessable_entity
        end
      end
    end
  end
end
