class Current < ActiveSupport::CurrentAttributes
  # Adicionamos o tenant_id aqui para o ApplicationJob conseguir usar
  attribute :user, :tenant, :tenant_id

  # Sobrescrevemos o setter para garantir que o ID mude junto com o objeto
  def tenant=(tenant)
    super
    self.tenant_id = tenant&.id
  end
end
