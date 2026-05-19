module Fleet
  module UseCases
    class FindTruck
      class << self
        def call(id, tenant_id)
          truck = Fleet::Truck.find_by(id: id, tenant_id: tenant_id)

          return Result.success(truck) if truck.present?
          Result.failure([ "Caminhão não encontrado" ], status: :not_found)
        end
      end
    end
  end
end
