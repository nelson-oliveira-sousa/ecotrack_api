class Waste::Reading < ApplicationRecord
  belongs_to :bin, class_name: "Waste::Bin"

  # Opcional: Garante que os dados fiquem guardados por ordem de chegada
  default_scope { order(created_at: :asc) }
end
