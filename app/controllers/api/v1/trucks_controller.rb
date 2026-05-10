module Api
  module V1
    class TrucksController < Api::V1::ApiController
      before_action :set_truck, only: [ :show, :update, :destroy, :update_location, :toggle_status ]

      def index
        trucks = Current.user.tenant.trucks
        data = Fleet::Serializers::TruckSerializer.render_collection(trucks)

        render_result(Result.new(success: true, data: data))
      end

      def show
        data = Fleet::Serializers::TruckSerializer.render(@truck)

        render_result(Result.new(success: true, data: data))
      end

      def create
        truck = Current.user.tenant.trucks.new(truck_params)

        if truck.save
          data = Fleet::Serializers::TruckSerializer.render(truck)
          render_result(Result.new(success: true, data: data, status: :created))
        else
          render_result(Result.new(success: false, error: truck.errors.full_messages, status: :unprocessable_entity))
        end
      end

      def update
        if @truck.update(truck_params)
          data = Fleet::Serializers::TruckSerializer.render(@truck)
          render_result(Result.new(success: true, data: data))
        else
          render_result(Result.new(success: false, error: @truck.errors.full_messages, status: :unprocessable_entity))
        end
      end

      def destroy
        if @truck.in_route?
          render_result(Result.new(success: false, error: "Não é possível remover um caminhão que está em circulação.", status: :unprocessable_entity))
        else
          @truck.destroy
          render_result(Result.new(success: true, data: { message: "Caminhão removido com sucesso." }))
        end
      end

      def update_location
        if @truck.update(location_params)
          data = Fleet::Serializers::TruckSerializer.render(@truck)
          render_result(Result.new(success: true, data: data))
        else
          render_result(Result.new(success: false, error: @truck.errors.full_messages, status: :unprocessable_entity))
        end
      end

      def toggle_status
        new_status = @truck.status == "available" ? "inactive" : "available"
        if @truck.update(status: new_status)
          data = Fleet::Serializers::TruckSerializer.render(@truck)
          render_result(Result.new(success: true, data: data, status: :ok))
        else
          render_result(Result.new(success: false, error: @truck.errors.full_messages, status: :unprocessable_entity))
        end
      end

      private

      def set_truck
        @truck = Current.user.tenant.trucks.find(params[:id])
      end

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
