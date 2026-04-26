# app/domains/waste/services/collect_bin_service.rb
module Waste
  module Services
    class CollectBinService
      def self.call(bin:, collected_at: nil)
        # 1. Atualiza o estado atual da lixeira
        # Certifique-se que o enum no model Bin foi corrigido de 'colleected' para 'collected'
        success = bin.update(
          level: 0,
          status: "collected"
        )

        if success
          # 2. Registra o evento de coleta no histórico (Readings)
          bin.readings.create!(
            level: 0,
            status: "collected",
            battery: bin.battery
          )
        end

        success
      end
    end
  end
end
