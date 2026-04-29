# app/models/fleet/route.rb
module Fleet
  class Route < ApplicationRecord
    belongs_to :tenant
    belongs_to :truck, class_name: "Fleet::Truck"
    belongs_to :driver, class_name: "User"

    has_many :route_points, class_name: "Fleet::RoutePoint", dependent: :destroy
    has_many :bins, through: :route_points, source: :waste_bin

    # active = Em andamento na rua
    enum :status, { planned: 0, active: 1, completed: 2, cancelled: 3 }, default: :planned

    validates :name, :date, presence: true

    # Regra de negócio: Apenas uma rota ativa por camião no mesmo dia
    validates :truck_id, uniqueness: { scope: [ :date, :status ], conditions: -> { where(status: :active) }, message: "já possui uma rota ativa hoje." }

    def lock!
      update(locked: true)
    end
  end
end
