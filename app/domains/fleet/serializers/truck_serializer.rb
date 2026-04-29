# app/domains/fleet/serializers/truck_serializer.rb
module Fleet
  module Serializers
    class TruckSerializer
      class << self
        def render(truck)
          { truck: render_as_hash(truck) }
        end

        def render_collection(trucks)
          { trucks: trucks.map { |truck| render_as_hash(truck) } }
        end

        def render_as_hash(truck)
          return nil unless truck

          {
            id: truck.id,
            plate: truck.plate,
            capacity: truck.capacity,
            status: truck.status,
            location: {
              latitude: truck.current_lat,
              longitude: truck.current_lng
            },
            created_at: truck.created_at,
            updated_at: truck.updated_at
          }
        end

        def render_errors(truck)
          { errors: truck.errors.full_messages }
        end
      end
    end
  end
end
