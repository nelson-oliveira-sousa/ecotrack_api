# app/models/tenant.rb
class Tenant < ApplicationRecord
  enum :status, { inactive: 0, active: 1 }, default: :active

  has_one :profile, class_name: "TenantProfile", dependent: :destroy
  has_many :waste_bins, class_name: "Waste::Bin", dependent: :destroy

  # 1. ADICIONADO: Necessário para o Onboarding (Tenant + Admin)
  has_many :users, dependent: :destroy

  accepts_nested_attributes_for :profile

  validates :name, :slug, :code, presence: true
  validates :slug, :code, uniqueness: true

  delegate :document, :contact_email, to: :profile, allow_nil: true

  before_validation :generate_tenant_code, on: :create
  before_validation :sanitize_slug

  private

  def sanitize_slug
    # 2. CORRIGIDO: Se o slug não for enviado, ele pega o nome (ex: "Prefeitura de Guaiçara" -> "prefeitura-de-guaicara")
    base_slug = slug.presence || name
    self.slug = base_slug.to_s.parameterize if base_slug.present?
  end

  def generate_tenant_code
    self.code ||= SecureRandom.alphanumeric(8).upcase
  end
end
