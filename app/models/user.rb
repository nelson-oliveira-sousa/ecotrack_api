class User < ApplicationRecord
  has_secure_password

  # 1. Opcional: Permite que tenant seja nulo para os vendedores/super_admin da sua empresa
  belongs_to :tenant, optional: true

  # 2. Novos papéis (Roles) divididos entre Sistema (Vocês) e Cliente (Prefeituras)
  enum :role, {
    # 👑 Nível Sistema (Sua Empresa - tenant_id: nil)
    super_admin: "super_admin",
    vendedor:    "vendedor",
    suporte:     "suporte",

    # 🏢 Nível Cliente (Prefeitura - tenant_id: obrigatório)
    admin:       "admin",
    driver:      "driver",
    collector:   "collector"
  }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # A unicidade com scope continua perfeita.
  # Vendedores (tenant_id: nil) não podem repetir email entre si.
  # Prefeituras não podem repetir email dentro do mesmo tenant.
  validates :email, uniqueness: { scope: :tenant_id }

  # 3. 🔥 REMOVIDO: validates :tenant, presence: true
  # SUBSTITUÍDO POR: Validação inteligente baseada na Role
  validate :tenant_presence_based_on_role

  # Sua validação de senha está excelente, intocada.
  validates :password, format: {
    with: /\A(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}\z/,
    message: "deve conter pelo menos 8 caracteres, uma letra, um número e um caractere especial"
  }, if: -> { new_record? || !password.nil? }

  # --- Métodos Auxiliares ---

  def system_user?
    super_admin? || vendedor? || suporte?
  end

  def tenant_user?
    admin? || driver? || collector?
  end

  private

  def tenant_presence_based_on_role
    if system_user? && tenant_id.present?
      errors.add(:tenant, "Usuários do sistema não devem pertencer a um tenant específico")
    elsif tenant_user? && tenant_id.blank?
      errors.add(:tenant, "Usuários da operação (Prefeitura) precisam pertencer a um tenant")
    end
  end
end
