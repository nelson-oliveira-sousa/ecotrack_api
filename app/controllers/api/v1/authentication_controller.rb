# app/controllers/api/v1/authentication_controller.rb
class Api::V1::AuthenticationController < Api::V1::ApiController
  skip_before_action :authorize_request, only: :login, raise: false

  def login
    result = Identity::Services::Authenticator.call(
      tenant_code: params[:tenant_code],
      email: params[:email],
      password: params[:password]
    )

    # Guard Clause: Se não for sucesso, já era.
    return render json: { error: result[:error] }, status: :unauthorized unless result[:success]

    # Caminho feliz sem else
    render json: result[:data], status: :ok
  end

  def logout
    token = request.headers["Authorization"]&.split(" ")&.last

    return render json: { error: "Token não fornecido" }, status: :bad_request if token.blank?

    result = Identity::Services::Revoker.call(token)

    return render json: { error: "Falha ao revogar token" }, status: :unprocessable_entity unless result[:success]

    render json: { message: "Logout bem-sucedido" }, status: :ok
  end
end
