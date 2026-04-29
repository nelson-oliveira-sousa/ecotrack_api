class CreateFleetRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_routes do |t|
      t.string :name, null: false
      t.date :date, null: false
      t.integer :status, default: 0
      t.boolean :locked, default: false

      t.references :tenant, null: false, foreign_key: true
      t.references :truck, null: false, foreign_key: { to_table: :fleet_trucks }
      # ADICIONAR to_table: :users para o driver
      t.references :driver, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
