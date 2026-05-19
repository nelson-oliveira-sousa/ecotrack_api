module Fleet
  module UseCases
    class DesactivateTruck
      class << self
        def call(id, tenant_id)
          truck = Fleet::Truck.find_by(id: id, tenant_id: tenant_id)

          return Result.failure([ "Caminhão não encontrado" ], status: :not_found) if truck.nil?

          return Result.success(truck) if truck.update(active: false)

          Result.failure(truck.errors.map do |error|
              {
                field: error.attribute.to_s,
                message: error.message
              }
            end
          )
        end
      end
    end
  end
end
