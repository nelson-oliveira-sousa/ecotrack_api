# app/domains/identity/forms/user_registration_form.rb
module Identity
  module Forms
    class UserRegistrationForm
      include ActiveModel::Model

      # Atributos comuns
      attr_accessor :email, :name, :role, :tenant_id
      # Atributos específicos de motorista
      attr_accessor :cnh_number, :cnh_expiration_date

      attr_reader :generated_password, :user

      # 1. Validações base para todos
      validates :email, :name, :role, presence: true
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :tenant_id, presence: true, unless: -> { role == "super_admin" }

      # 2. Validações condicionais: "Se for motorista, inclua os campos que precisa"
      validates :cnh_number, :cnh_expiration_date, presence: true, if: :driver?

      def save
        return false unless valid?

        # 3. Gera a senha provisória seguindo as regras de segurança
        @generated_password = "#{SecureRandom.alphanumeric(8)}A1@"

        @user = User.new(user_attributes)
        @user.password = @generated_password
        @user.force_password_change = true
        @user.status = :active

        @user.save
      end

      private

      def driver?
        role == "driver"
      end

      def user_attributes
        attrs = {
          email: email,
          name: name,
          role: role,
          tenant_id: tenant_id
        }

        # Inclui campos de motorista apenas se necessário
        if driver?
          attrs.merge!(
            cnh_number: cnh_number,
            cnh_expiration_date: cnh_expiration_date
          )
        end

        attrs
      end
    end
  end
end
