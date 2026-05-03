module Api
  module V1
    class BinsController < ApiController
      before_action :set_bin, only: [ :show, :collect ]

      # GET /api/v1/bins
      def index
        # Usamos a associação direta pelo tenant para garantir o isolamento
        bins = Current.tenant.waste_bins

        data = Waste::Serializers::BinSerializer.render_collection(bins)
        render_result(Result.new(success: true, data: data))
      end

      # GET /api/v1/bins/:id
      def show
        data = Waste::Serializers::BinSerializer.render(@bin)
        render_result(Result.new(success: true, data: data))
      end

      # POST /api/v1/bins
      def create
        bin = Current.tenant.waste_bins.new(bin_params)

        # Regra de inicialização simples (o ideal seria colocar no after_initialize do Model Waste::Bin)
        bin.level ||= 0

        if bin.save
          data = Waste::Serializers::BinSerializer.render(bin)
          render_result(Result.new(success: true, data: data, status: :created))
        else
          # Delegamos o array de erros para o padrão Result
          render_result(Result.new(success: false, error: bin.errors.full_messages, status: :unprocessable_entity))
        end
      end

      # PATCH /api/v1/bins/:id/collect
      def collect
        # 🚀 O Controller apenas orquestra chamando o Service!
        # NOTA: O CollectBinService precisa ser atualizado para herdar de ApplicationService
        result = Waste::Services::CollectBinService.call(
          bin: @bin,
          collected_at: params[:collected_at]
        )

        if result.success?
          # O Service fez o trabalho, agora o Controller formata a resposta atualizada
          data = Waste::Serializers::BinSerializer.render(@bin)
          render_result(Result.new(success: true, data: data, status: :ok))
        else
          # Repassa a falha estruturada do Service
          render_result(result)
        end
      end

      private

      def set_bin
        # ❌ REMOVIDO: rescue ActiveRecord::RecordNotFound e render_not_found customizado.
        # Nosso ApiResponder captura a exceção de find! e devolve o JSON perfeitamente formatado.
        @bin = Current.tenant.waste_bins.find(params[:id])
      end

      def bin_params
        params.require(:bin).permit(
          :label, :sensor_id, :status, :battery,
          bin_address_attributes: [ :address, :number, :neighborhood, :city, :state, :zip_code, :latitude, :longitude ]
        )
      end
    end
  end
end
