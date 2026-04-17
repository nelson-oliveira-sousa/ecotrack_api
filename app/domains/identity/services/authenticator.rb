# app/domains/identity/services/authenticator.rb
module Identity
  module Services
    class Authenticator
      def self.call(tenant_code:, email:, password:)
        tenant = Tenant.find_by(code: tenant_code)
        return { success: false, error: "Ambiente inválido" } unless tenant
        return { success: false, error: "Ambiente inativo" } if tenant.inactive?

        user = User.find_by(tenant_id: tenant.id, email: email)

        if user&.authenticate(password)
          token = TokenManager.encode(user_id: user.id, tenant_id: user.tenant.id)

          {
            success: true,
            data: {
              access_token: token,
              token_type: "bearer",
              user: Serializers::UserSerializer.render(user),
              tenant: Serializers::TenantSerializer.render(tenant)
            }
          }
        else
          { success: false, error: "Prefeitura, e-mail ou senha inválidos" }
        end
      end
    end
  end
end
