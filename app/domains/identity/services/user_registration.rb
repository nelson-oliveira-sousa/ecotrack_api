# app/domains/identity/services/user_registration.rb
module Identity
  module Services
    class UserRegistration
      def self.call(tenant, params)
        user = tenant.users.build(params)

        # Gera uma senha provisória de 6 caracteres (ex: "8f3a9d")
        temp_password = params[:password].presence || SecureRandom.hex(3)
        user.password = temp_password

        # A MÁGICA: Liga a trava do primeiro acesso!
        user.force_password_change = true

        if user.save
          OpenStruct.new(success?: true, user: user, temp_password: temp_password)
        else
          OpenStruct.new(success?: false, errors: user.errors.full_messages)
        end
      end
    end
  end
end
