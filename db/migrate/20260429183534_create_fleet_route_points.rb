class CreateFleetRoutePoints < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_route_points do |t|
      t.references :route, null: false, foreign_key: { to_table: :fleet_routes }
      t.references :waste_bin, null: false, foreign_key: { to_table: :waste_bins }
      t.integer :position, default: 0
      t.boolean :collected, default: false
      t.datetime :collected_at

      t.timestamps
    end

    # Índice importante para performance ao ordenar a rota
    add_index :fleet_route_points, [ :route_id, :position ]
  end
end
