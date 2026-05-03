module Dashboard
  module Services
    class SummaryService < ApplicationService
      def initialize(tenant:)
        @tenant = tenant
      end

      def call
        # Agregando informações do domínio Waste
        counts = Waste::Bin.where(tenant: @tenant).group(:status).count

        # Chamada a um Query Object: Excelente padrão!
        next_bin = Waste::Queries::NextPriorityBinQuery.call(tenant: @tenant)

        # Senior Tip: Use render_as_hash (se for Blueprinter) ou .as_json para não encadear Strings JSON
        serialized_bin = if next_bin
                           Waste::Serializers::BinSerializer.render_as_hash(next_bin)
        else
                           nil
        end

        data = {
          critical_count: counts["critical"] || 0,
          warning_count: counts["warning"] || 0,
          collected_count: counts["collected"] || 0,
          next_priority_bin: serialized_bin
        }

        # Padronizado com o nosso Result global!
        success(data)
      rescue StandardError => e
        # Proteção contra quedas no banco durante cálculos analíticos
        failure("Erro ao gerar o resumo do dashboard: #{e.message}", :internal_server_error)
      end
    end
  end
end
