# app/domains/fleet/serializers/truck_serializer.rb
module Fleet
  module Serializers
    class TruckSerializer
      class << self
        def render_as_hash(resource)
          return resource.map { |truck| render(truck) } if resource.response_to?(:as_array)
          render(resource)
        end

        def render(truck)
          return nil unless truck

          {
            id: truck.id,
            plate: truck.plate,
            model: truck.model,
            capacity: truck.capacity,
            renavam: truck.renavam,
            manufacture_year: truck.manufacture_year,
            document_expiration_date: truck.document_expiration_date,
            status: truck.status,
            created_at: truck.created_at,
            updated_at: truck.updated_at
          }
        end
      end
    end
  end
end
