class ApplicationJob < ActiveJob::Base
  attr_accessor :tenant_id

  before_enqueue do |job|
    job.tenant_id = Current.tenant_id
  end

  # Corrigido: around_perform (com apenas um 'r')
  around_perform do |job, block|
    if job.tenant_id
      Current.tenant = Tenant.find(job.tenant_id)
      block.call
    else
      block.call
    end
  ensure
    Current.reset
  end

  def serialize
    super.merge("tenant_id" => tenant_id || Current.tenant_id)
  end

  def deserialize(job_data)
    super
    self.tenant_id = job_data["tenant_id"]
  end
end
