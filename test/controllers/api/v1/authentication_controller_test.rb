require "test_helper"

class Api::V1::AuthenticationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = tenants(:one)
    @user = users(:one)
    # Assumindo que a fixture tem uma senha válida hasheada, ou mockamos aqui:
    @user.update!(tenant: @tenant, password: "Password123!")
  end

  test "deve logar com credenciais validas e retornar token" do
    post api_v1_login_url, params: {
      tenant_code: @tenant.code,
      email: @user.email,
      password: "Password123!"
    }, as: :json

    assert_response :ok
    assert json_response[:success]
    assert_not_nil json_response.dig(:data, :access_token)
    assert_nil json_response[:error]
  end

  test "nao deve logar com senha invalida" do
    post api_v1_login_url, params: {
      tenant_code: @tenant.code,
      email: @user.email,
      password: "wrongpassword"
    }, as: :json

    assert_response :unauthorized
    assert_not json_response[:success]
    assert_nil json_response[:data]
    assert_equal "Prefeitura, e-mail ou senha inválidos", json_response[:error]
  end
end
