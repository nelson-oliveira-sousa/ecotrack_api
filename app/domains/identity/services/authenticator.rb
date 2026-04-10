# app/domains/identity/services/authenticator.rb
module Identity
  module Services
    class Authenticator
      def self.call(tenant_slug:, email:, password:)
        user = User.find_by(tenant_slug: tenant_slug, email: email)

        if user&.authenticate(password)
          token = TokenManager.encode(user_id: user.id, tenant_slug: user.tenant_slug)

          {
            success: true,
            data: {
              token: token,
              user: Serializers::UserSerializer.render(user)
            }
          }
        else
          { success: false, error: "Prefeitura, e-mail ou senha inválidos" }
        end
      end
    end
  end
end
