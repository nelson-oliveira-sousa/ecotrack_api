# app/jobs/fleet/generate_routes_job.rb
module Fleet
  class GenerateRoutesJob < ApplicationJob
    queue_as :default

    def perform(tenant_id)
      tenant = Tenant.find(tenant_id)

      # Chama o serviço de domínio que fará o trabalho pesado[cite: 1]
      Fleet::Services::RouteGenerator.call(tenant: tenant)
    rescue => e
      Rails.logger.error("Falha fatal no GenerateRoutesJob: #{e.message}")
      # Opcional: Aqui você também poderia mandar um NOTIFY de erro fatal
    end
  end
end
