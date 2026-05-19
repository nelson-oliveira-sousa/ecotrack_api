# app/controllers/api/v1/trucks_controller.rb
module Api
  module V1
    class TrucksController < Api::V1::ApiController
      # O ApiResponder fornece o método respond_with_result
      include ApiResponder

      def index
        # Idealmente, você pode criar um Fleet::UseCases::ListTrucks no futuro
        trucks = Current.user.tenant.trucks

        respond_with_result(
          Result.success(trucks),
          serializer: Fleet::Serializers::TruckSerializer
        )
      end

      def show
        result = Fleet::UseCases::FindTruck.call(params[:id], Current.user.tenant_id)

        respond_with_result(result, serializer: Fleet::Serializers::TruckSerializer)
      end

      def create
        result = Fleet::UseCases::CreateTruck.call(
          truck_params.merge(tenant_id: Current.user.tenant_id)
        )

        respond_with_result(result, serializer: Fleet::Serializers::TruckSerializer)
      end

      def update
        result = Fleet::UseCases::UpdateTruck.call(
          params[:id],
          truck_params.merge(tenant_id: Current.user.tenant_id)
        )

        respond_with_result(result, serializer: Fleet::Serializers::TruckSerializer)
      end

      def deactivate
        result = Fleet::UseCases::DeactivateTruck.call(params[:id], Current.user.tenant_id)

        respond_with_result(result, serializer: Fleet::Serializers::TruckSerializer)
      end

      # Ações específicas podem ter seus próprios Use Cases ou Services se a lógica crescer
      def update_location
        truck = Current.user.tenant.trucks.find(params[:id])

        if truck.update(location_params)
          respond_with_result(Result.success(truck), serializer: Fleet::Serializers::TruckSerializer)
        else
          respond_with_result(Result.failure(truck.errors))
        end
      end

      def toggle_status
        truck = Current.user.tenant.trucks.find(params[:id])
        new_status = truck.status == "available" ? "inactive" : "available"

        if truck.update(status: new_status)
          respond_with_result(Result.success(truck), serializer: Fleet::Serializers::TruckSerializer)
        else
          respond_with_result(Result.failure(truck.errors))
        end
      end

      private

      def truck_params
        params.require(:truck).permit(
          :plate, :model, :capacity,
          :renavam, :manufacture_year, :document_expiration_date
        )
      end

      def location_params
        params.require(:location).permit(:current_lat, :current_lng)
      end
    end
  end
end
