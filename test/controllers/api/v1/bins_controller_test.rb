require "test_helper"

class Api::V1::BinsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tenant = @user.tenant
    @headers = auth_headers_for(@user, "Password123!")
  end

  test "deve listar lixeiras do tenant com formato padronizado" do
    get api_v1_bins_url, headers: @headers, as: :json

    assert_response :ok
    assert json_response[:success]
    assert_kind_of Array, json_response[:data]
  end

  test "deve criar lixeira e retornar HTTP 201 Created" do
    post api_v1_bins_url, params: {
      bin: {
        label: "Lixeira Teste E2E",
        sensor_id: "SENSOR_TEST_99",
        status: "active"
      }
    }, headers: @headers, as: :json

    assert_response :created
    assert json_response[:success]
    assert_equal "Lixeira Teste E2E", json_response.dig(:data, :label)
    assert_equal 0, json_response.dig(:data, :level) # Valor padrão garantido no controller
  end

  test "deve capturar RecordNotFound via ApiResponder e retornar padronizado" do
    get api_v1_bin_url(id: 999999), headers: @headers, as: :json

    assert_response :not_found
    assert_not json_response[:success]
    assert_match /Registro não encontrado/, json_response[:error]
  end
end
