# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # Opcional para super_admins/vendedores, obrigatório para clientes (validado no Form/Service)
  belongs_to :tenant, optional: true

  # Papéis (Roles) divididos entre Sistema e Cliente
  enum :role, {
    # Nível Sistema
    super_admin: "super_admin",
    vendedor:    "vendedor",
    suporte:     "suporte",

    # Nível Cliente (Prefeitura)
    admin:       "admin",
    driver:      "driver",
    collector:   "collector"
  }

# Status padronizado como String (Épico 2)
enum :status, {
    active: 1,
    inactive: 2,
    suspended: 0
  }, default: :active

  # Validações estruturais absolutas
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :tenant_id }
  validates :name, presence: true
  validates :force_password_change, inclusion: { in: [ true, false ] }

  # Validação de senha delegada ao validador do domínio Identity (Épico 1)
  # A lógica de complexidade sai do model e vai para o domínio
  validates_with Identity::Validators::PasswordFormatValidator, attributes: [ :password ], if: -> { new_record? || !password.nil? }

  # Métodos Auxiliares de Domínio
  def system_user?
    super_admin? || vendedor? || suporte?
  end

  def tenant_user?
    admin? || driver? || collector?
  end
end
