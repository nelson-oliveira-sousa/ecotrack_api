# app/jobs/fleet/generate_routes_job.rb
module Fleet
  class GenerateRoutesJob < ApplicationJob
    queue_as :default

    def perform(tenant_id)
      tenant = Tenant.find(tenant_id)
      result = Fleet::Services::RouteGenerator.call(tenant: tenant)

      Rails.logger.error("Falha ao gerar rotas: #{result.error}") if result.failure?
    rescue => e
      Rails.logger.error("Falha fatal no GenerateRoutesJob: #{e.message}")
    end
  end
end
