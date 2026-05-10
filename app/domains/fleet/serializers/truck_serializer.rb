# app/domains/fleet/serializers/truck_serializer.rb
module Fleet
  module Serializers
    class TruckSerializer
      class << self
        def render_collection(trucks)
          trucks.map { |truck| render(truck) }
        end

        def render(truck)
          return nil unless truck

          {
            id: truck.id,
            plate: truck.plate,
            capacity: truck.capacity,
            status: StatusCatalog.normalize(truck.status),
            model: truck.model,

            # Novos campos de documentação do caminhão
            renavam: truck.renavam,
            manufacture_year: truck.manufacture_year,
            document_expiration_date: truck.document_expiration_date,

            location: {
              latitude: truck.current_lat,
              longitude: truck.current_lng
            },
            created_at: truck.created_at,
            updated_at: truck.updated_at
          }
        end

        # Removido o 'self.' pois já estamos dentro de 'class << self'
        def render_as_hash(resource)
          resource.respond_to?(:map) ? render_collection(resource) : render(resource)
        end

        def render_errors(truck)
          { errors: truck.errors.full_messages }
        end
      end
    end
  end
end
