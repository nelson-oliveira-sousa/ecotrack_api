module Api
  module V1
    class RoutesController < Api::V1::ApiController
      include ActionController::Live

      before_action :set_route, only: [ :start, :collect_stop ]

      # ==========================================
      # 🤖 FASE 1: GERAÇÃO COM INTELIGÊNCIA ARTIFICIAL
      # ==========================================

      def generate
        Fleet::GenerateRoutesJob.perform_later(Current.user.tenant.id)

        render_result(Result.new(
          success: true,
          data: { message: "Análise de rota enfileirada. Acompanhe o progresso pelo canal de streaming." },
          status: :accepted
        ))
      end

      def stream
        # ⚡ EXCEÇÃO DA ARQUITETURA:
        # Endpoints de Streaming (SSE) não usam o `render_result` pois não devolvem um JSON único.
        # Eles mantêm uma conexão aberta enviando múltiplos pacotes de dados.
        response.headers["Content-Type"] = "text/event-stream"
        response.headers["Last-Modified"] = Time.now.httpdate
        response.headers["Cache-Control"] = "no-cache"
        response.headers["X-Accel-Buffering"] = "no"

        tenant = Current.user.tenant
        channel = "alerts_tenant_#{tenant.id}"

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
            Rails.logger.info "Conexão SSE do Tenant #{tenant.id} fechada."
          ensure
            connection.execute("UNLISTEN #{channel}")
            response.stream.close
          end
        end
      end

      # ==========================================
      # 🚚 FASE 2: OPERAÇÃO EM CAMPO (MOTORISTAS)
      # ==========================================

      def today
        routes = Current.user.tenant.routes
                            .where(date: Date.current)
                            .includes(route_points: :waste_bin)

        # O ideal aqui é depois criar um Fleet::Serializers::RouteSerializer
        data = {
          routes: routes.as_json(
            include: {
              route_points: {
                include: { waste_bin: { only: [ :id, :label, :level, :status ] } }
              }
            }
          )
        }

        render_result(Result.new(success: true, data: data))
      end

      def start
        # Regras de validação de estado (State Machine) também podem ir para um Service no futuro.
        if @route.planned?
          @route.update!(status: :active)
          render_result(Result.new(
            success: true,
            data: { message: "Rota iniciada com sucesso!", status: @route.status }
          ))
        else
          render_result(Result.new(
            success: false,
            error: "Apenas rotas planeadas podem ser iniciadas.",
            status: :unprocessable_entity
          ))
        end
      end

      def collect_stop
        # 🚀 O Controller agora apenas orquestra! Ele delega o trabalho pesado para o Service.
        result = Fleet::Services::CollectStop.call(
          route: @route,
          bin_id: params[:bin_id]
        )

        render_result(result)
      end

      private

      def set_route
        @route = Current.user.tenant.routes.find(params[:id])
      end
    end
  end
end
