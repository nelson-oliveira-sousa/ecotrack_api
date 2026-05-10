require "test_helper"

class IotIngestionFlowTest < ActionDispatch::IntegrationTest
  setup do
    # Usando as fixtures geradas pelo Rails
    @tenant = tenants(:one)
    @user = users(:one)

    # Garantimos que o usuário pertence ao tenant e tem uma senha conhecida
    @user.update!(tenant: @tenant, password: "Password123!")
  end

  test "E2E: Login, Cadastro de Lixeira, Ingestão MQTT e Processamento Assíncrono" do
    # ==========================================
    # FASE 1: Autenticação (Testando o AuthController e ApiResponder)
    # ==========================================
    post api_v1_login_url, params: {
      tenant_code: @tenant.code,
      email: @user.email,
      password: "Password123!"
    }, as: :json

    assert_response :ok
    assert json_response[:success], "Falha no login E2E"

    token = json_response.dig(:data, :access_token)
    auth_headers = { "Authorization" => "Bearer #{token}" }

    # ==========================================
    # FASE 2: Criar Lixeira (Testando BinsController)
    # ==========================================
    post api_v1_bins_url, params: {
      bin: {
        label: "Lixeira Av. Paulista",
        sensor_id: "ESP32_PAULISTA_01",
        status: "active",
        bin_address_attributes: {
          address: "Avenida Paulista",
          number: "1000",
          neighborhood: "Bela Vista",
          city: "São Paulo",
          state: "SP",
          zip_code: "01310-100",
          latitude: -23.561684,
          longitude: -46.655981
        }
      }
    }, headers: auth_headers, as: :json

    assert_response :created
    assert json_response[:success], "Falha ao criar lixeira"

    bin_id = json_response.dig(:data, :id)
    assert_not_nil bin_id

    # Verifica se a lixeira nasceu vazia (regra de negócio do controller)
    bin = Waste::Bin.find(bin_id)
    assert_equal 0, bin.level

    # ==========================================
    # FASE 3: Simular Ingestão MQTT (Inbox Pattern)
    # ==========================================
    payload = {
      "deviceInfo" => { "devEui" => "ESP32_PAULISTA_01" },
      "object" => { "level" => 88, "battery" => 95 }
    }

    mqtt_message = MqttMessage.create!(
      tenant: @tenant,
      event_id: SecureRandom.uuid,
      topic: "application/1/device/ESP32_PAULISTA_01/rx",
      payload: payload,
      status: :new
    )

    assert_equal "new", mqtt_message.status

    # ==========================================
    # FASE 4: Processar a Mensagem (Simulando o Background Job)
    # ==========================================
    MqttBatchProcessorJob.perform_now

    # Garante que a mensagem saiu da fila
    mqtt_message.reload
    assert_equal "processed", mqtt_message.status
    assert_equal @tenant.id, mqtt_message.tenant_id

    # ==========================================
    # FASE 5: Verificação Final de Estado
    # ==========================================
    bin.reload

    # 1. A lixeira física deve estar atualizada
    assert_equal 88, bin.level
    assert_equal 95, bin.battery
    # assert_equal "critical", bin.status (Se você tiver implementado o BinStatusResolver)

    # 2. O histórico imutável deve ter sido criado
    assert_equal 1, bin.readings.count
    last_reading = bin.readings.last
    assert_equal 88, last_reading.level
    assert_equal 95, last_reading.battery

    # 3. O endpoint de visualização deve refletir a mudança imediatamente
    get api_v1_bin_url(bin_id), headers: auth_headers, as: :json
    assert_response :ok
    assert_equal 88, json_response.dig(:data, :level)
  end
end
