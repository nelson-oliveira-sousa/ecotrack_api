module Identity
  module Services
    class UserRegistration < ApplicationService
      def initialize(tenant:, user_params:)
        @tenant = tenant
        @user_params = user_params
      end

      def call
        form = Identity::Forms::UserRegistrationForm.new(@user_params)
        form.tenant_id = @tenant&.id if form.tenant_id.blank?

        return success({
            user: form.user,
            temp_password: form.user.password
        }, :created) if form.save

        failure(form.user.errors.full_messages, :unprocessable_entity)
      rescue StandardError => e
        failure("Erro ao registrar usuário: #{e.message}", :internal_server_error)
      end
    end
  end
end
