# app/domains/tenants/serializers/validation.rb
module Tenants
  module Serializers
    class Validation
      def self.render(tenant)
        {
          exists: true,
          tenant_code: tenant.code,
          tenant_name: tenant.name,
          tenant_type: "prefeitura",
          status: tenant.status
        }
      end
    end
  end
end
