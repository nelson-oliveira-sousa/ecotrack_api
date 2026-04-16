class TenantProfile < ApplicationRecord
  belongs_to :tenant

  validates :document, presence: true, uniqueness: true

  # Limpeza automática de CNPJ antes de salvar
  before_validation :clean_document

  private

  def clean_document
    self.document = document.to_s.gsub(/\D/, "") if document.present?
  end
end
