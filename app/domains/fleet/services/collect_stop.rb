# app/domains/fleet/services/collect_stop.rb
module Fleet
  module Services
    class CollectStop < ApplicationService
      def initialize(route:, bin_id:)
        @route = route
        @bin_id = bin_id
      end

      def call
        return failure("A rota precisa estar ativa para registar recolhas.", :unprocessable_entity) unless @route.active?

        route_point = @route.route_points.find_by(waste_bin_id: @bin_id)

        return failure("Esta lixeira não pertence à rota atual.", :not_found) unless route_point

        # A transação ocorre na camada de domínio, nunca no Controller
        ActiveRecord::Base.transaction do
          route_point.mark_as_collected!
          route_point.waste_bin.update!(level: 0)
        end

        success({
          message: "Lixeira recolhida com sucesso!",
          bin_id: route_point.waste_bin_id,
          collected_at: route_point.collected_at
        })
      rescue StandardError => e
        failure("Erro ao processar recolha: #{e.message}", :internal_server_error)
      end
    end
  end
end
