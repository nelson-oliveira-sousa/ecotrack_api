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
          status: StatusCatalog.normalize(user.status),
          tenant_id: user.tenant_id,
          created_at: user.created_at,

          # Novos campos de documento para os motoristas
          cnh_number: user.cnh_number,
          cnh_category: user.cnh_category,
          cnh_expiration_date: user.cnh_expiration_date
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
