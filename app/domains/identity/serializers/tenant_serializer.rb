# app/domains/identity/serializers/tenant_serializer.rb
module Identity
  module Serializers
    class TenantSerializer
      def self.render(tenant)
        {
          id: tenant.id,
          name: tenant.name,
          tenant_code: tenant.code, # O que vai no X-Tenant-Code
          type: tenant.respond_to?(:tenant_type) ? tenant.tenant_type : "prefeitura",
          document: tenant.respond_to?(:document) ? tenant.document : "00.000.000/0001-00",
          status: tenant.status
        }
      end
    end
  end
end
