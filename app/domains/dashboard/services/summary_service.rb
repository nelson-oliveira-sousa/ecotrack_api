module Dashboard
  module Services
    class SummaryService
      def self.call(tenant:)
        # O Dashboard consome informações do domínio Waste
        counts = Waste::Bin.where(tenant: tenant).group(:status).count
        next_bin = Waste::Queries::NextPriorityBinQuery.call(tenant: tenant)

        # Amanhã você pode adicionar aqui:
        # active_trucks = Logistics::Queries::ActiveTrucksQuery.call(tenant: tenant)

        {
          critical_count: counts["critical"] || 0,
          warning_count: counts["warning"] || 0,
          collected_count: counts["collected"] || 0,
          next_priority_bin: next_bin ? Waste::Serializers::BinSerializer.render(next_bin) : nil
        }
      end
    end
  end
end
