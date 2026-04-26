module Waste
  module Services
    class CollectBinService
      def self.call(bin:, collected_at: nil)
        collection_time = collected_at || Time.current

        # Regra de negócio: Zera o nível, atualiza status e registra a data da coleta
        success = bin.update(
          level: 0,
          status: "collected",
          last_collection: collection_time
        )

        # Cria um histórico para mostrar que foi esvaziada
        if success
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
