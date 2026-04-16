# app/models/tenant.rb
class Tenant < ApplicationRecord
  # 1. Definições de Estado
  enum :status, { inactive: 0, active: 1 }, default: :active

  # 2. Relacionamentos
  # O profile guarda dados sensíveis/fiscais (1:1)
  has_one :profile, class_name: "TenantProfile", dependent: :destroy
  # As lixeiras são o core do domínio Waste
  has_many :waste_bins, class_name: "Waste::Bin", dependent: :destroy

  accepts_nested_attributes_for :profile

  # 3. Validações
  # O 'code' é o nosso Public ID (imutável) e o 'slug' é a nossa URL amigável
  validates :name, :slug, :code, presence: true
  validates :slug, :code, uniqueness: true

  # 4. Delegações (Lei de Demeter)
  delegate :document, :contact_email, to: :profile, allow_nil: true

  # 5. Callbacks de Segurança (AppSec)
  before_validation :generate_tenant_code, on: :create
  before_validation :sanitize_slug

  private

  # Garante que o Guaiçara SP vire guaicara-sp antes de bater no banco
  def sanitize_slug
    self.slug = slug.to_s.parameterize if slug.present?
  end

  # Gera o identificador único para o JWT e Login (ex: A1B2C3D4)
  def generate_tenant_code
    self.code ||= SecureRandom.alphanumeric(8).upcase
  end
end
