module Identity
  module Services
    class UserRegistration < ApplicationService
      def initialize(tenant:, user_params:)
        @tenant = tenant
        @user_params = user_params
      end

      def call
        user = @tenant.users.build(@user_params)
        user.password = temp_password
        user.force_password_change = true
        user.status = active_status

        return success({ user: user, temp_password: user.password }, :created) if user.save

        failure(user.errors.full_messages, :unprocessable_entity)
      rescue StandardError => e
        failure("Erro ao registrar usuário: #{e.message}", :internal_server_error)
      end

      private

      def temp_password
        SecureRandom.hex(3)
      end

      def active_status
        :active
      end
    end
  end
end
