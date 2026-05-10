# app/domains/identity/services/authenticator.rb
module Identity
  module Services
    class Authenticator < ApplicationService
      def initialize(tenant_code:, email:, password:)
        @tenant_code = tenant_code
        @email = email
        @password = password
      end

      def call
        tenant = Tenant.find_by(code: tenant_code)

        return failure("Ambiente inválido", :unauthorized) unless tenant
        return failure("Ambiente inativo", :unauthorized) if tenant.inactive?

        user = User.find_by(tenant_id: tenant.id, email: email)

        return failure("Prefeitura, e-mail ou senha inválidos", :unauthorized) unless user&.authenticate(password)

        token = TokenManager.encode(user_id: user.id, tenant_id: user.tenant.id)

        success(
          access_token: token,
          token: token,
          token_type: "bearer",
          user: Serializers::UserSerializer.render(user),
          tenant: Serializers::TenantSerializer.render(tenant)
        )
      end

      private

      attr_reader :tenant_code, :email, :password
    end
  end
end
