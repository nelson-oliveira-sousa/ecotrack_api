# app/domains/tenants/services/validate.rb
module Tenants
  module Services
    class Validate
      def self.call(slug)
        return { success: false, error: "Slug não fornecido", status: :bad_request } if slug.blank?

        # Blindagem: "Guaiçara SP" -> "guaicara-sp"
        clean_slug = slug.to_s.parameterize

        tenant = Tenant.find_by(slug: clean_slug)

        return { success: false, error: "Prefeitura não encontrada", status: :not_found } unless tenant
        return { success: false, error: "Acesso suspenso", status: :forbidden } if tenant.inactive?

        { success: true, tenant: tenant, status: :ok }
      end
    end
  end
end
