# app/controllers/api/v1/passwords_controller.rb
module Api
  module V1
    class PasswordsController < Api::V1::ApiController
      # PATCH /api/v1/update_password
      def update
        user = current_user

        # 1. Valida se ele sabe a senha atual/provisória
        unless user.authenticate(params[:current_password])
          return render json: { error: "Senha atual incorreta." }, status: :unauthorized
        end

        # 2. Atualiza e desliga o Enforce
        if user.update(password: params[:new_password], force_password_change: false)
          # Invalida o token atual para forçar novo login se desejar maior segurança
          token = extract_token
          Identity::Services::Revoker.call(token) if token # Usa seu Revoker já existente

          render json: { message: "Senha atualizada com sucesso. Faça login novamente." }, status: :ok
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
