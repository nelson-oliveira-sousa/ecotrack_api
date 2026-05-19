module Fleet
  module UseCases
    class CreateTruck < Shared::UseCases::FormUseCase
      class << self
        private

        def form_class
          Fleet::Forms::TruckForm
        end

        def success_status
          :created
        end
      end
    end
  end
end
