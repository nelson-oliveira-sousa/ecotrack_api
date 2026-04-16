# app/domains/identity/serializers/user_serializer.rb
module Identity
  module Serializers
    class UserSerializer
      def self.render(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          tenant: user.tenant.slug # O front-end costuma preferir só "tenant" na resposta
        }
      end
    end
  end
end
