# app/domains/identity/services/authenticator.rb
module Identity
  module Services
    class Authenticator
      def self.call(tenant_code:, email:, password:)
        tenant = Tenant.find_by(code: tenant_code)

        # 404 Not Found (or 401 Unauthorized, depending on your security preference)
        return Result.new(success: false, error: "Ambiente inválido", status: :unauthorized) unless tenant

        # 403 Forbidden or 401
        return Result.new(success: false, error: "Ambiente inativo", status: :unauthorized) if tenant.inactive?

        user = User.find_by(tenant_id: tenant.id, email: email)

        if user&.authenticate(password)
          token = TokenManager.encode(user_id: user.id, tenant_id: user.tenant.id)

          # Returns 200 OK implicitly because of the default status: :ok in Result
          Result.new(
            success: true,
            data: {
              access_token: token,
              token: token,
              token_type: "bearer",
              user: Serializers::UserSerializer.render(user),
              tenant: Serializers::TenantSerializer.render(tenant)
            }
          )
        else
          # Explicit 401 Unauthorized
          Result.new(success: false, error: "Prefeitura, e-mail ou senha inválidos", status: :unauthorized)
        end
      end
    end
  end
end
