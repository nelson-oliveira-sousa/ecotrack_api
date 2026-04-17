# app/domains/identity/serializers/user_serializer.rb
module Identity
  module Serializers
    class UserSerializer
      def self.render(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role
        }
      end
    end
  end
end
