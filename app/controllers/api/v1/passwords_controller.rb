# app/controllers/api/v1/passwords_controller.rb
class Api::V1::PasswordsController < Api::V1::ApiController
  def update_password
    user = Current.user

    unless user.authenticate(params[:current_password])
      return render json: { error: "Senha atual incorreta." }, status: :unauthorized
    end

    if user.update(password: params[:new_password], force_password_change: false)
      # Segurança: Invalida o token atual para forçar novo login com a senha nova
      token = request.headers["Authorization"]&.split(" ")&.last
      Identity::Services::Revoker.call(token) if token

      render json: { message: "Senha atualizada com sucesso. Por segurança, faça login novamente." }, status: :ok
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
