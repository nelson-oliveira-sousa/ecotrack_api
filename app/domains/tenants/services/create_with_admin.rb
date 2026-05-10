# app/domains/tenants/services/create_with_admin.rb
module Tenants
  module Services
    class CreateWithAdmin < ApplicationService
      def initialize(tenant_params:, admin_params:)
        @tenant_params = tenant_params
        @admin_params = admin_params
      end

      def call
        tenant = Tenant.new(
          name: @tenant_params[:name],
          status: :active
        )

        tenant.build_profile(
          document: @tenant_params[:document],
          contact_email: @tenant_params[:contact_email],
          contact_phone: @tenant_params[:contact_phone]
        )

        temporary_password = @admin_params[:password].presence || SecureRandom.hex(3)
        admin = tenant.users.build(
          name: @admin_params[:name],
          email: @admin_params[:email],
          role: :admin,
          status: :active,
          force_password_change: true,
          password: temporary_password
        )

        ActiveRecord::Base.transaction do
          tenant.save!
        end

        success({ tenant: tenant, admin: admin, temporary_password: temporary_password }, :created)
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages, :unprocessable_entity)
      rescue ActiveRecord::RecordNotUnique => e
        failure(e.message, :unprocessable_entity)
      end
    end
  end
end
