module Api
  module V1
    class AuthenticationController < Api::V1::ApiController
      skip_before_action :authorize_request, only: :login, raise: false
      skip_before_action :enforce_password_change!, only: :login

      # POST /api/v1/auth/login
      def login
        # 🚀 O Service faz o trabalho sujo.
        # Ele deve retornar um Result contendo o token e os dados já serializados no 'data'
        result = Identity::Services::Authenticator.call(
          tenant_code: params[:tenant_code],
          email: params[:email],
          password: params[:password]
        )

        # O ApiResponder lida com o if/else de sucesso e erro automaticamente!
        render_result(result)
      end

      # DELETE /api/v1/auth/logout
      def logout
        token = request.headers["Authorization"]&.split(" ")&.last

        if token.blank?
          return render_result(Result.new(
            success: false,
            error: "Token não fornecido",
            status: :bad_request
          ))
        end

        result = Identity::Services::Revoker.call(token)

        if result.success?
          # Traduzimos o sucesso "vazio" do Service para uma mensagem amigável de saída
          render_result(Result.new(success: true, data: { message: "Logout bem-sucedido" }))
        else
          render_result(result)
        end
      end

      # GET /api/v1/auth/me
      def me
        # Como o authorize_request já rodou, os dados estão garantidos no Current
        data = {
          user: Identity::Serializers::UserSerializer.render(Current.user),
          tenant: Identity::Serializers::TenantSerializer.render(Current.tenant)
        }

        render_result(Result.new(success: true, data: data))
      end
    end
  end
end
