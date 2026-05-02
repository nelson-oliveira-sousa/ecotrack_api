# app/domains/identity/serializers/user_serializer.rb
module Identity
  module Serializers
    class UserSerializer
      def self.render(user, options = {})
        payload = {
          id: user.id,
          name: user.name,
          email: user.email,
          status: user.status,
          role: user.role
        }

        if options[:include_force_change]
          payload[:force_password_change] = user.force_password_change
        end

        # Só incluímos se a senha temporária existir (ex: no momento do create)
        if options[:temporary_password].present?
          payload[:temporary_password] = options[:temporary_password]
        end

        payload
      end

      def self.render_collection(users)
        users.map { |user| render(user) }
      end
    end
  end
end
