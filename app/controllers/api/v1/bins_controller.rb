module Api
  module V1
    class BinsController < ApiController
      skip_before_action :authorize_request, only: :sensor, raise: false
      before_action :set_bin, only: [ :show, :update, :collect, :destroy, :toggle_status ]

      # GET /api/v1/bins
      def index
        # Usamos a associação direta pelo tenant para garantir o isolamento
        bins = Current.tenant.waste_bins
                              .includes(:bin_address, :last_collected_reading)

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

      # PATCH /api/v1/bins/:id/collect
      def collect
        # 🚀 O Controller apenas orquestra chamando o Service!
        # NOTA: O CollectBinService precisa ser atualizado para herdar de ApplicationService
        result = Waste::Services::CollectBinService.call(
          bin: @bin,
          collected_at: params[:collected_at]
        )

        if result
          # O Service fez o trabalho, agora o Controller formata a resposta atualizada
          data = Waste::Serializers::BinSerializer.render(@bin)
          render_result(Result.new(success: true, data: data, status: :ok))
        else
          # Repassa a falha estruturada do Service
          render_result(result)
        end
      end

      def toggle_status
        puts "🚀 [BinsController#toggle_status] Lixeira ID: #{@bin.id}, Status Atual: #{@bin.equipment_status}"
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
        return render_result(Result.new(success: false, error: "Lixeira não encontrada", status: :not_found)) unless bin

        level = params[:level]
        battery = params[:battery]

        if level.blank?
          return render_result(Result.new(success: false, error: "Parâmetro level é obrigatório", status: :bad_request))
        end

        ActiveRecord::Base.transaction do
          bin.update!(level: level.to_i, battery: battery.presence || bin.battery)
          bin.readings.create!(
            level: bin.level,
            battery: bin.battery,
            status: bin.status
          )
        end

        Waste::AiAnalysisJob.perform_later(bin.id) if bin.analysis_needed?

        data = Waste::Serializers::BinSerializer.render(bin)
        render_result(Result.new(success: true, data: data, status: :accepted))
      rescue ActiveRecord::RecordInvalid => e
        render_result(Result.new(success: false, error: e.record.errors.full_messages, status: :unprocessable_entity))
      end

      private

      def set_bin
        # ❌ REMOVIDO: rescue ActiveRecord::RecordNotFound e render_not_found customizado.
        # Nosso ApiResponder captura a exceção de find! e devolve o JSON perfeitamente formatado.
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
