module Api
  module V1
    class BinsController < ApiController
      before_action :set_bin, only: [ :show, :collect ]

      # GET /api/v1/bins
      def index
        # Garante o isolamento multi-tenant
        @bins ||= Waste::Bin.where(tenant: Current.tenant)

        render json: Waste::Serializers::BinSerializer.render_collection(@bins), status: :ok
      end

      # GET /api/v1/bins/:id
      def show
        render json: Waste::Serializers::BinSerializer.render(@bin), status: :ok
      end

      # PATCH /api/v1/bins/:id/collect
      def collect
        success = Waste::Services::CollectBinService.call(
          bin: @bin,
          collected_at: params[:collected_at]
        )

        if success
          # Retorna o JSON atualizado e formatado (nível 0)
          render json: Waste::Serializers::BinSerializer.render(@bin), status: :ok
        else
          render json: Waste::Serializers::BinSerializer.render_errors(@bin), status: :unprocessable_entity
        end
      end

      private

      def set_bin
        @bin ||= Waste::Bin.find_by!(id: params[:id], tenant: Current.tenant)
      rescue ActiveRecord::RecordNotFound
        render json: Waste::Serializers::BinSerializer.render_not_found, status: :not_found
      end

      def bin_params
        params.require(:bin).permit(
          :label, :dev_eui, :status, :battery,
          bin_address_attributes: [ :address, :number, :neighborhood, :city, :state, :zip_code ]
        )
      end
    end
  end
end
