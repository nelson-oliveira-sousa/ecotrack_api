class CreateFleetTrucks < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_trucks do |t|
      t.string :plate
      t.integer :capacity
      t.integer :status, default: 0

      # Adicionada a precisão de 10 dígitos totais, com 6 casas decimais (Padrão GPS)
      t.decimal :current_lat, precision: 10, scale: 6
      t.decimal :current_lng, precision: 10, scale: 6

      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
