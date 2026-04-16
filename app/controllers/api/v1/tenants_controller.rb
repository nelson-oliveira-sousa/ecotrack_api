# app/controllers/api/v1/tenants_controller.rb
module Api
  module V1
    class TenantsController < Api::V1::ApiController
      # Rota pública para identificação de ambiente
      skip_before_action :authorize_request, only: [ :validate ], raise: false

      def validate
        # O Rails injeta o :slug da rota no params automaticamente
        result = Tenants::Services::Validate.call(params[:slug])

        unless result[:success]
          return render json: {
            exists: false,
            message: result[:error]
          }, status: result[:status]
        end

        # Sucesso: Passa pelo Serializer do Domínio
        render json: Tenants::Serializers::Validation.render(result[:tenant]), status: :ok
      end
    end
  end
end
