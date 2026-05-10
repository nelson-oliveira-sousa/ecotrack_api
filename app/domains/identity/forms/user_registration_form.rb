# app/domains/identity/forms/user_registration_form.rb
module Identity
  module Forms
    class UserRegistrationForm
      include ActiveModel::Model

      attr_accessor :email, :name, :role, :tenant_id,
                    :cnh_number, :cnh_expiration_date, :cnh_category
      attr_reader :generated_password, :user

      validates :email, :name, :role, :tenant_id, presence: true
      validates :cnh_number, :cnh_expiration_date, presence: true, if: -> { role == "driver" }

      def save
        return false unless valid?

        @user = build_user

        @user.save.tap { |success| errors.merge!(@user.errors) unless success }
      end

      private

      def build_user
        @generated_password = generate_secure_password
        User.new(all_attributes)
      end

      def all_attributes
        base_attributes.merge(RoleAttributesResolver.resolve(self))
      end

      def base_attributes
        {
          email: email,
          name: name,
          role: role,
          tenant_id: tenant_id,
          password: @generated_password,
          force_password_change: true,
          status: :active
        }
      end

      def generate_secure_password
        "#{SecureRandom.alphanumeric(10)}!1A"
      end
    end
  end
end
