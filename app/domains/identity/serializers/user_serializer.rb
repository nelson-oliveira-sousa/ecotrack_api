# app/domains/identity/serializers/user_serializer.rb
module Identity
  module Serializers
    class UserSerializer
      class << self
        def render(user, options = {})
          return {} unless user

          new(user, options).as_json
        end

        def render_collection(users, options = {})
          users.map { |user| render(user, options) }
        end
      end

      def initialize(user, options = {})
        @user = user
        @options = options
      end

      def as_json
        # Junta o básico, com o específico, com o opcional. Lindo e direto.
        base_attributes
          .merge(RoleAttributesResolver.resolve(user))
          .merge(optional_attributes)
      end

      private

      attr_reader :user, :options

      def base_attributes
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          status: StatusCatalog.normalize(user.status),
          tenant_id: user.tenant_id,
          created_at: user.created_at&.iso8601
        }
      end

      def optional_attributes
        attrs = {}
        attrs[:force_password_change] = user.force_password_change if options[:include_force_change]
        attrs[:temporary_password] = options[:temporary_password] if options[:temporary_password].present?
        attrs
      end
    end
  end
end
