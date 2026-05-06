require "test_helper"

class ResultTest < ActiveSupport::TestCase
  test "deve inicializar com sucesso e conter dados" do
    result = Result.new(success: true, data: { id: 1 }, status: :ok)

    assert result.success?
    assert_not result.failure?
    assert_equal({ id: 1 }, result.data)
    assert_nil result.error
    assert_equal :ok, result.status
  end

  test "deve inicializar como falha e conter erro" do
    result = Result.new(success: false, error: "Acesso negado", status: :unauthorized)

    assert result.failure?
    assert_not result.success?
    assert_nil result.data
    assert_equal "Acesso negado", result.error
    assert_equal :unauthorized, result.status
  end

  test "deve formatar corretamente para hash" do
    result = Result.new(success: true, data: { name: "Eco" }).to_h

    assert result[:success]
    assert_equal "Eco", result[:data][:name]
    assert_nil result[:error]
  end
end
