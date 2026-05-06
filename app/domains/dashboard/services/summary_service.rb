module Dashboard
  module Services
    class SummaryService < ApplicationService
      # 🚀 Sênior: Use keyword arguments para clareza e flexibilidade
      def initialize(tenant:)
        @tenant = tenant
      end

      def call
        # 🚀 FIX: Usamos tenant_id explicitamente para evitar o erro PG::UndefinedTable.
        # Isso remove a necessidade de um JOIN implícito que o Postgres não consegue resolver no GROUP BY.
        counts = Waste::Bin.where(tenant_id: @tenant.id).group(:status).count

        # Query Object mantido (excelente padrão de separação)
        next_bin = Waste::Queries::NextPriorityBinQuery.call(tenant: @tenant)

        # Garantimos que o serializer retorne um Hash para evitar double-encoding no JSON
        serialized_bin = next_bin ? Waste::Serializers::BinSerializer.render_as_hash(next_bin) : nil

        data = {
          critical_count: counts["critical"] || 0,
          warning_count: counts["warning"] || 0,
          collected_count: counts["collected"] || 0,
          next_priority_bin: serialized_bin
        }

        # Agora utiliza o método success da classe pai ApplicationService
        success(data)
      rescue StandardError => e
        # O método failure agora aceita os argumentos corretamente,
        # sem gerar erro de assinatura (ArgumentError).
        failure("Erro ao gerar o resumo do dashboard: #{e.message}", :internal_server_error)
      end
    end
  end
end
