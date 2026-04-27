module Waste
  module Serializers
    class BinSerializer
      def self.render(bin)
       {
          id: bin.id,
          name: bin.label,
          level: bin.level,
          battery: bin.battery,
          status: bin.status,
          dev_eui: bin.dev_eui, # Importante para debug técnico

          # 🔥 OS CAMPOS DA IA (O grande diferencial da demo)
          ai_insight: bin.ai_prediction,
          predicted_full_at: bin.predicted_full_at&.strftime("%H:%M"),
          last_analysis_at: bin.last_analysis_at,

          route_name: "Não Atribuída",

          # 📍 ENDEREÇO E LOCALIZAÇÃO (Buscando da tabela associada)
          address: bin.full_address,
          location: {
            latitude: bin.bin_address&.latitude,
            longitude: bin.bin_address&.longitude
          },

          updated_at: bin.updated_at,
          last_collection: bin.last_collection
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
