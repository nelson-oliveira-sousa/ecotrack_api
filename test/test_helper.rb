# test/test_helper.rb
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # ==========================================
    # 🛠 HELPERS CUSTOMIZADOS DA NOSSA API
    # ==========================================

    # Facilita a leitura do JSON retornado pela API e permite acessar chaves
    # tanto como string ('success') quanto como symbol (:success).
    def json_response
      ::JSON.parse(response.body).with_indifferent_access
    end

    # Helper para autenticar rapidamente qualquer usuário das fixtures
    # Uso no teste: get api_v1_bins_url, headers: auth_headers_for(users(:nelson))
    def auth_headers_for(user, password = "Password123!")
      # O nosso código usa o padrão Result agora!
      result = Identity::Services::Authenticator.call(
        tenant_code: user.tenant.code,
        email: user.email,
        password: password
      )

      if result.success?
        token = result.data[:access_token] || result.data[:token]
        { "Authorization" => "Bearer #{token}" }
      else
        raise "Falha ao autenticar na fixture de testes: #{result.error}"
      end
    end
  end
end
