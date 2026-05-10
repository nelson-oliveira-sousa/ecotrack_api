module Waste
  module Serializers
    class BinSerializer
      def self.render(bin)
        return nil unless bin

        {
          id: bin.id,
          label: bin.label,
          level: bin.level || 0,
          battery: bin.battery,
          status: StatusCatalog.normalize(bin.status),
          sensor_id: bin.sensor_id,

          ai_insight: bin.ai_prediction,
          predicted_full_at: bin.predicted_full_at&.strftime("%H:%M"),
          last_analysis_at: bin.last_analysis_at,
          equipment_status: StatusCatalog.normalize(bin.equipment_status),

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
          last_collection: bin.last_collection
        }
      end

      def self.render_as_hash(resource)
        resource.respond_to?(:map) ? render_collection(resource) : render(resource)
      end

      def self.render_collection(bins)
        bins.map { |bin| render(bin) }
      end

      def self.render_errors(bin)
        { success: false, error: bin.errors.full_messages }
      end
    end
  end
end
