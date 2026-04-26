module Waste
  module Queries
    class NextPriorityBinQuery
      # Usamos o .call para manter o padrão de invocação simples e direto
      def self.call(tenant:)
        Waste::Bin.where(tenant: tenant)
                  .where(status: [ "critical", "warning" ])
                  .order(level: :desc)
                  .first
      end
    end
  end
end
