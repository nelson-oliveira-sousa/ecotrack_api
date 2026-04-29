# app/models/fleet/route_point.rb
module Fleet
  class RoutePoint < ApplicationRecord
    belongs_to :route, class_name: "Fleet::Route"
    belongs_to :waste_bin, class_name: "Waste::Bin"

    # Ordena automaticamente pela posição (1, 2, 3...)
    default_scope { order(position: :asc) }

    def mark_as_collected!(time = Time.current)
      update!(collected: true, collected_at: time)
    end
  end
end
