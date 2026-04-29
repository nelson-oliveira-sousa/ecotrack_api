# app/models/fleet/truck.rb
module Fleet
  class Truck < ApplicationRecord
    # 1. Associações
    belongs_to :tenant
    has_many :routes, class_name: "Fleet::Route", dependent: :restrict_with_error

    # 2. Estado do Camião
    enum :status, { available: 0, in_route: 1, maintenance: 2, inactive: 3 }, default: :available

    # 3. Validações
    validates :plate, presence: true, uniqueness: { case_sensitive: false }
    validates :capacity, presence: true, numericality: { greater_than: 0 }

    # Formato de placa padrão Mercosul ou Antigo
    validates :plate, format: {
      with: /\A[A-Z]{3}-?[0-9][A-Z0-9][0-9]{2}\z/i,
      message: "deve seguir o padrão Mercosul ou antigo"
    }

    # 4. Callbacks
    before_validation :upcase_plate

    private

    def upcase_plate
      self.plate = plate.to_s.upcase.gsub(/[^A-Z0-9]/, "") if plate.present?
    end
  end
end
