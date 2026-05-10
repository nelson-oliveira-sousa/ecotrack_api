module Api
  module V1
    class TenantsController < Api::V1::ApiController
      # Rota pública para identificação do login (Frontend)
      skip_before_action :authorize_request, only: [ :validate ], raise: false

      # Exemplo de autorização para onboarding comercial
      # before_action :authorize_system_user!, only: [:create]

      # GET /api/v1/tenants/validate/:slug
      def validate
        # O Service Tenants::Services::Validate precisa ser refatorado para usar o ApplicationService
        result = Tenants::Services::Validate.call(params[:slug])

        if result.success?
          data = Tenants::Serializers::Validation.render(result.data)
          render_result(Result.new(success: true, data: data))
        else
          # Passamos o result inteiro para renderizar a falha com a mensagem e o status (ex: :not_found)
          render_result(result)
        end
      end

      # POST /api/v1/tenants
      def create
        # O Service CreateWithAdmin também precisa retornar um Result(success:, data:, error:)
        result = Tenants::Services::CreateWithAdmin.call(
          tenant_params: tenant_params,
          admin_params: admin_params
        )

        if result.success?
          data = {
            message: "Prefeitura cadastrada com sucesso!",
            tenant: result.data[:tenant].as_json(only: [ :id, :name, :slug, :code, :status ]),
            admin: result.data[:admin].as_json(only: [ :id, :name, :email, :role ]),
            temporary_password: result.data[:temporary_password]
          }

          render_result(Result.new(success: true, data: data, status: :created))
        else
          render_result(result)
        end
      end

      private

      def authorize_system_user!
        unless Current.user&.system_user?
          # Renderizando a falha de autorização via ApiResponder
          render_result(Result.new(
            success: false,
            error: "Apenas a equipe comercial pode cadastrar prefeituras.",
            status: :forbidden
          ))
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
