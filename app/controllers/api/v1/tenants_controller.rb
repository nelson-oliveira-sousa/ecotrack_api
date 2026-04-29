# app/controllers/api/v1/tenants_controller.rb
module Api
  module V1
    class TenantsController < Api::V1::ApiController
      # Rota pública para identificação do login (Frontend)
      skip_before_action :authorize_request, only: [ :validate ], raise: false

      # Protege a rota de criação (se você usa :authorize_request no seu ApiController)
      # before_action :authorize_system_user!, only: [:create]

      # GET /api/v1/tenants/:slug/validate
      def validate
        result = Tenants::Services::Validate.call(params[:slug])

        unless result[:success]
          return render json: {
            exists: false,
            message: result[:error]
          }, status: result[:status]
        end

        render json: Tenants::Serializers::Validation.render(result[:tenant]), status: :ok
      end

      # POST /api/v1/tenants
      def create
        result = Tenants::Services::CreateWithAdmin.call(
          tenant_params: tenant_params,
          admin_params: admin_params
        )

        if result[:success]
          render json: {
            message: "Prefeitura cadastrada com sucesso!",
            tenant: result[:tenant].as_json(only: [ :id, :name, :slug, :code, :status ]),
            admin: result[:admin].as_json(only: [ :id, :name, :email, :role ])
          }, status: :created
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def authorize_system_user!
        # Ajuste conforme o método que você usa para pegar o usuário logado (Current.user, @current_user, etc)
        unless Current.user&.system_user?
          render json: { error: "Apenas a equipe comercial pode cadastrar prefeituras." }, status: :forbidden
        end
      end

      def tenant_params
        params.require(:tenant).permit(:name, :document, :contact_email, :contact_phone)
      end

      def admin_params
        params.require(:admin).permit(:name, :email, :password)
      end
    end
  end
end
