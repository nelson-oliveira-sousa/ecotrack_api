module Waste
  module Serializers
    class BinSerializer
      def self.render(bin)
        {
          id: bin.id,
          name: bin.label, # De -> Para (Banco -> Frontend)
          district: bin.district,
          level: bin.level,
          battery: bin.battery, # O dado preditivo!
          status: bin.status,
          route_name: "Não Atribuída", # Deixaremos fixo até criarmos o Módulo Logístico
          address: bin.address,
          updated_at: bin.updated_at,
          last_collection: bin.last_collection,
          location: {
            latitude: bin.latitude,
            longitude: bin.longitude
          }
        }
      end

      def self.render_collection(bins)
        bins.map { |bin| render(bin) }
      end

      def self.render_errors(bin)
        { errors: bin.errors.full_messages }
      end

      def self.render_not_found
        { error: "Lixeira não encontrada ou não pertence a este tenant" }
      end
    end
  end
end
