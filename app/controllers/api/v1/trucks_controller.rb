module Api
  module V1
    class TrucksController < Api::V1::ApiController
      before_action :set_truck, only: [ :show, :update, :destroy, :update_location ]

      # GET /api/v1/trucks
      def index
        trucks = Current.user.tenant.trucks
        data = Fleet::Serializers::TruckSerializer.render_collection(trucks)

        render_result(Result.new(success: true, data: data))
      end

      # GET /api/v1/trucks/:id
      def show
        data = Fleet::Serializers::TruckSerializer.render(@truck)

        render_result(Result.new(success: true, data: data))
      end

      # POST /api/v1/trucks
      def create
        truck = Current.user.tenant.trucks.new(truck_params)

        if truck.save
          data = Fleet::Serializers::TruckSerializer.render(truck)
          render_result(Result.new(success: true, data: data, status: :created))
        else
          # Aqui abandonamos o TruckSerializer.render_errors em favor do padrão global
          render_result(Result.new(success: false, error: truck.errors.full_messages, status: :unprocessable_entity))
        end
      end

      # PATCH/PUT /api/v1/trucks/:id
      def update
        if @truck.update(truck_params)
          data = Fleet::Serializers::TruckSerializer.render(@truck)
          render_result(Result.new(success: true, data: data))
        else
          render_result(Result.new(success: false, error: @truck.errors.full_messages, status: :unprocessable_entity))
        end
      end

      # DELETE /api/v1/trucks/:id
      def destroy
        # REGRA DE NEGÓCIO: Idealmente isso iria para um Service (ex: Fleet::Services::DestroyTruck.call),
        # mas mantemos aqui por enquanto usando o padrão Result.
        if @truck.in_route?
          render_result(Result.new(success: false, error: "Não é possível remover um caminhão que está em circulação.", status: :unprocessable_entity))
        else
          @truck.destroy
          render_result(Result.new(success: true, data: { message: "Caminhão removido com sucesso." }))
        end
      end

      # PATCH /api/v1/trucks/:id/location
      def update_location
        if @truck.update(location_params)
          data = Fleet::Serializers::TruckSerializer.render(@truck)
          render_result(Result.new(success: true, data: data))
        else
          render_result(Result.new(success: false, error: @truck.errors.full_messages, status: :unprocessable_entity))
        end
      end

      private

      def set_truck
        @truck = Current.user.tenant.trucks.find(params[:id])
        # ❌ REMOVIDO: rescue ActiveRecord::RecordNotFound
        # Por que? Porque o nosso ApiResponder agora pega isso de forma global e
        # devolve um JSON padronizado. Menos código para nós mantermos!
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
