# app/domains/tenants/services/validate.rb
module Tenants
  module Services
    class Validate < ApplicationService
      def initialize(slug)
        @slug = slug
      end

      def call
        return failure("Slug não fornecido", :bad_request) if @slug.blank?

        # Blindagem: "Guaiçara SP" -> "guaicara-sp"
        clean_slug = @slug.to_s.parameterize
        tenant = Tenant.find_by(slug: clean_slug)

        return failure("Prefeitura não encontrada", :not_found) unless tenant
        return failure("Acesso suspenso", :forbidden) if tenant.inactive?

        # Agora retorna Result.new(success: true, data: tenant, status: :ok)
        success(tenant)
      end
    end
  end
end
