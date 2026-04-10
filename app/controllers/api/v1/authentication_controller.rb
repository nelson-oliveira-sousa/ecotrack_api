# app/controllers/api/v1/authentication_controller.rb
class Api::V1::AuthenticationController < Api::V1::ApiController
  skip_before_action :authorize_request, only: :login, raise: false

  def login
    result = Identity::Services::Authenticator.call(
      tenant_slug: params[:tenant_slug],
      email: params[:email],
      password: params[:password]
    )

    if result[:success]
      render json: result[:data], status: :ok
    else
      render json: { error: result[:error] }, status: :unauthorized
    end
  end

  def logout
    header =  request.headers["Authorization"]
    token = header.split(" ").last if header

    return render json: { error: "Token de autenticação não fornecido" }, status: :bad_request unless token

    result = Identity::Services::Revoker.call(token)

    return render json: { error: "Falha ao revogar token" }, status: :unprocessable_entity unless result[:success]

    render json: { message: "Logout bem-sucedido" }, status: :ok
  end
end
