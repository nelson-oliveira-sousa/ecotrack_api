# app/controllers/api/v1/trucks_controller.rb
module Api
  module V1
    class TrucksController < Api::V1::ApiController
      before_action :set_truck, only: [ :show, :update, :destroy, :update_location ]

      # GET /api/v1/trucks
      def index
        trucks = Current.user.tenant.trucks
        render json: Fleet::Serializers::TruckSerializer.render_collection(trucks), status: :ok
      end

      # GET /api/v1/trucks/:id
      def show
        render json: Fleet::Serializers::TruckSerializer.render(@truck), status: :ok
      end

      # POST /api/v1/trucks
      def create
        truck = Current.user.tenant.trucks.new(truck_params)

        if truck.save
          render json: Fleet::Serializers::TruckSerializer.render(truck), status: :created
        else
          render json: Fleet::Serializers::TruckSerializer.render_errors(truck), status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/trucks/:id
      def update
        if @truck.update(truck_params)
          render json: Fleet::Serializers::TruckSerializer.render(@truck), status: :ok
        else
          render json: Fleet::Serializers::TruckSerializer.render_errors(@truck), status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/trucks/:id
      def destroy
        if @truck.in_route?
          render json: { error: "Não é possível remover um camião que está em circulação." }, status: :unprocessable_entity
        else
          @truck.destroy
          render json: { message: "Camião removido com sucesso." }, status: :ok
        end
      end

      # PATCH /api/v1/trucks/:id/location
      def update_location
        if @truck.update(location_params)
          render json: Fleet::Serializers::TruckSerializer.render(@truck), status: :ok
        else
          render json: Fleet::Serializers::TruckSerializer.render_errors(@truck), status: :unprocessable_entity
        end
      end

      private

      def set_truck
        @truck = Current.user.tenant.trucks.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Camião não encontrado." }, status: :not_found
      end

      def truck_params
        params.require(:truck).permit(:plate, :capacity, :status)
      end

      def location_params
        params.require(:location).permit(:current_lat, :current_lng)
      end
    end
  end
end
