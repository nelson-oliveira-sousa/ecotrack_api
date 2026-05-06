module Waste
  module Serializers
    class BinSerializer
      # Método principal para transformar a Model em Hash
      def self.render(bin)
        return nil unless bin

        {
          id: bin.id,
          label: bin.label, # Mantido 'label' para bater com o Vue.js
          level: bin.level || 0,
          battery: bin.battery,
          status: bin.status,
          sensor_id: bin.sensor_id, # Alinhado com o banco

          # 🔥 OS CAMPOS DA IA
          ai_insight: bin.ai_prediction,
          predicted_full_at: bin.predicted_full_at&.strftime("%H:%M"),
          last_analysis_at: bin.last_analysis_at,
          equipment_status: bin.equipment_status,

          # 📍 ENDEREÇO E LOCALIZAÇÃO
          # O método full_address na Model já foi otimizado
          address: bin.full_address,
          location: {
            latitude: bin.bin_address&.latitude,
            longitude: bin.bin_address&.longitude
          },

          address_components: {
            address: bin.bin_address&.address,
            number: bin.bin_address&.number,
            neighborhood: bin.bin_address&.neighborhood,
            city: bin.bin_address&.city,
            state: bin.bin_address&.state,
            zip_code: bin.bin_address&.zip_code
          },

          updated_at: bin.updated_at,
          # Usa a associação last_collected_reading pré-carregada pelo includes
          last_collection: bin.last_collection
        }
      end

      def self.render_as_hash(resource)
              resource.respond_to?(:map) ? render_collection(resource) : render(resource)
            end


      def self.render_collection(bins)
        puts "Serializando coleção de bins: #{bins.size} itens encontrados." # Debug para verificar o número de bins
        # Retorna um array de hashes para evitar double-encoding no JSON final[cite: 1]
        bins.map { |bin| render(bin) }
      end

      # Helpers para erros e estados (opcional, já que o ApiResponder cuida disso)[cite: 1]
      def self.render_errors(bin)
        { success: false, error: bin.errors.full_messages }
      end
    end
  end
end
