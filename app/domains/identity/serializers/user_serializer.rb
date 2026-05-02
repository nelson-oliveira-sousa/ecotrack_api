# app/domains/identity/serializers/user_serializer.rb
module Identity
  module Serializers
    class UserSerializer
      def self.render(user, options = {})
        return {} unless user

        payload = {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          status: user.status,
          tenant_id: user.tenant_id,
          created_at: user.created_at
        }

        # Campos opcionais para Login e Cadastro
        payload[:force_password_change] = user.force_password_change if options[:include_force_change]
        payload[:temporary_password] = options[:temporary_password] if options[:temporary_password].present?

        payload
      end

      def self.render_collection(users)
        users.map { |user| render(user) }
      end
    end
  end
end
