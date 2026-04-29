# app/controllers/api/v1/routes_controller.rb
module Api
  module V1
    class RoutesController < Api::V1::ApiController
      before_action :set_route, only: [ :start, :collect_stop ]

      # GET /api/v1/routes/today
      def today
        # Traz as rotas de hoje do Tenant, já com os pontos de paragem e lixeiras incluídos (para evitar N+1 queries)
        routes = Current.user.tenant.routes
                            .where(date: Date.current)
                            .includes(route_points: :waste_bin)

        # Como ainda não temos um Serializer complexo para a rota,
        # devolvemos a estrutura desenhada nas suas anotações
        render json: {
          routes: routes.as_json(
            include: {
              route_points: {
                include: { waste_bin: { only: [ :id, :label, :level, :status ] } }
              }
            }
          )
        }, status: :ok
      end

      # POST /api/v1/routes/:id/start
      def start
        if @route.planned?
          @route.update!(status: :active)
          render json: { message: "Rota iniciada com sucesso!", status: @route.status }, status: :ok
        else
          render json: { error: "Apenas rotas planeadas podem ser iniciadas." }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/routes/:id/stops/:bin_id/collect
      def collect_stop
        # 1. Validação de Segurança: O camião tem de estar na rua
        unless @route.active?
          return render json: { error: "A rota precisa estar ativa para registar recolhas." }, status: :unprocessable_entity
        end

        # 2. Encontra a paragem específica desta lixeira dentro da rota
        route_point = @route.route_points.find_by(waste_bin_id: params[:bin_id])

        if route_point
          # 3. Executa a lógica de forma atómica (Tudo ou Nada)
          ActiveRecord::Base.transaction do
            # Marca o ponto da rota como coletado
            route_point.mark_as_collected!

            # ATENÇÃO: Integração com a Fase 3! Esvazia a lixeira fisicamente no sistema
            route_point.waste_bin.update!(level: 0)
          end

          render json: {
            message: "Lixeira recolhida com sucesso!",
            bin_id: route_point.waste_bin_id,
            collected_at: route_point.collected_at
          }, status: :ok
        else
          render json: { error: "Esta lixeira não pertence à rota atual." }, status: :not_found
        end
      end

      private

      def set_route
        @route = Current.user.tenant.routes.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Rota não encontrada." }, status: :not_found
      end
    end
  end
end
