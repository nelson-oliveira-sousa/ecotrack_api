module Waste
  class BinAddress < ApplicationRecord
    # Relacionamento com a lixeira
    belongs_to :waste_bin, class_name: "Waste::Bin"

    # Validações de presença para garantir que a localização seja útil para o motorista
    validates :address, :neighborhood, :city, :state, presence: true

    # Validação simples de CEP brasileiro
    validates :zip_code, format: { with: /\A\d{5}-?\d{3}\z/, message: "formato inválido (ex: 16430-000)" }, allow_blank: true
  end
end
