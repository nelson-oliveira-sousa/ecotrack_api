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
            status: truck.status,
            model: truck.model,
            location: {
              latitude: truck.current_lat,
              longitude: truck.current_lng
            },
            created_at: truck.created_at,
            updated_at: truck.updated_at
          }
        end

         def self.render_as_hash(resource)
              resource.respond_to?(:map) ? render_collection(resource) : render(resource)
            end


        def render_errors(truck)
          { errors: truck.errors.full_messages }
        end
      end
    end
  end
end
