module Fleet
  module UseCases
    class UpdateTruck < Shared::UseCases::FormUseCase
      class << self
        def call(id, params)
          super(params.merge(id: id))
        end

        private

        def form_class
          Fleet::Forms::TruckForm
        end
      end
    end
  end
end
