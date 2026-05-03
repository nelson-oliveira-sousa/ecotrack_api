# app/controllers/api/v1/passwords_controller.rb
module Api
  module V1
    class PasswordsController < Api::V1::ApiController
      def update_password
        # O Controller extrai os parâmetros do protocolo HTTP...
        token = request.headers["Authorization"]&.split(" ")&.last

        # ... e delega para a camada de Domínio.
        result = Identity::Services::UpdatePassword.call(
          user: Current.user,
          current_password: params[:current_password],
          new_password: params[:new_password],
          token: token
        )

        # A resposta é devolvida padronizada (success, data, error)
        render_result(result)
      end
    end
  end
end
