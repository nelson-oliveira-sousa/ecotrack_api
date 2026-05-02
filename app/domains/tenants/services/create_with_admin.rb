# app/domains/tenants/services/create_with_admin.rb
module Tenants
  module Services
    class CreateWithAdmin
      def self.call(params)
        tenant = Tenant.new(
          name: params[:name],
          code: params[:code],
          status: :active
        )

        tenant.build_tenant_profile(params[:profile_attributes])

        # Prepara o usuário admin daquela prefeitura
        admin = tenant.users.build(
          name: params.dig(:admin_attributes, :name),
          email: params.dig(:admin_attributes, :email),
          role: :admin,
          status: :active,
          force_password_change: true # Cai na trava de segurança que fizemos antes!
        )

        # Gera senha amigável (ex: 9f2a1b)
        temp_password = SecureRandom.hex(3)
        admin.password = temp_password

        ActiveRecord::Base.transaction do
          tenant.save!
          # Se passar daqui, salvou o tenant, o profile e o usuário atrelado a ele.
        end

        { success: true, tenant: tenant, admin: admin, temp_password: temp_password }
      rescue ActiveRecord::RecordInvalid => e
        { success: false, errors: e.record.errors.full_messages }
      rescue => e
        { success: false, errors: [ e.message ] }
      end
    end
  end
end
