module Api
  module V1
    class BinsController < ApiController
      skip_before_action :authorize_request, only: :sensor, raise: false
      before_action :set_bin, only: [ :show, :update, :collect, :destroy, :toggle_status ]

      def index
        bins = Current.tenant.waste_bins
                              .includes(:bin_address, :last_collected_reading)

        data = Waste::Serializers::BinSerializer.render_collection(bins)
        render_result(Result.new(success: true, data: data))
      end

      def show
        data = Waste::Serializers::BinSerializer.render(@bin)
        render_result(Result.new(success: true, data: data))
      end

      def create
        bin = Current.tenant.waste_bins.new(bin_params)
        bin.level ||= 0

        if bin.save
          data = Waste::Serializers::BinSerializer.render(bin)
          render_result(Result.new(success: true, data: data, status: :created))
        else
          render_result(Result.new(success: false, error: bin.errors.full_messages, status: :unprocessable_entity))
        end
      end

      def update
        if @bin.update(bin_params)
          data = Waste::Serializers::BinSerializer.render(@bin)
          render_result(Result.new(success: true, data: data, status: :ok))
        else
          render_result(Result.new(success: false, error: @bin.errors.full_messages, status: :unprocessable_entity))
        end
      end

      def destroy
        if @bin.update(equipment_status: "offline")
          data = Waste::Serializers::BinSerializer.render(@bin)
          render_result(Result.new(success: true, data: data, status: :ok))
        else
          render_result(Result.new(success: false, error: @bin.errors.full_messages, status: :unprocessable_entity))
        end
      end

      def collect
        result = Waste::Services::CollectBinService.call(
          bin: @bin,
          collected_at: params[:collected_at]
        )

        return render_result(result) if result.failure?

        data = Waste::Serializers::BinSerializer.render(result.data[:bin])
        render_result(Result.new(success: true, data: data, status: :ok))
      end

      def toggle_status
        new_status = @bin.equipment_status == "online" ? "offline" : "online"
        if @bin.update(equipment_status: new_status)
          data = Waste::Serializers::BinSerializer.render(@bin)
          render_result(Result.new(success: true, data: data, status: :ok))
        else
          render_result(Result.new(success: false, error: @bin.errors.full_messages, status: :unprocessable_entity))
        end
      end

      def sensor
        bin = Waste::Bin.find_by(id: params[:id])
        result = Waste::Services::RecordReading.call(
          bin: bin,
          level: params[:level],
          battery: params[:battery],
          raw_payload: params.to_unsafe_h.except("controller", "action")
        )

        return render_result(result) if result.failure?

        data = Waste::Serializers::BinSerializer.render(result.data[:bin])
        render_result(Result.new(success: true, data: data, status: :accepted))
      end

      private

      def set_bin
        @bin = Current.tenant.waste_bins.find(params[:id])
      end

      def bin_params
        params.require(:bin).permit(
          :label, :sensor_id, :battery,
          bin_address_attributes: [ :address, :number, :neighborhood, :city, :state, :zip_code, :latitude, :longitude ]
        )
      end
    end
  end
end
