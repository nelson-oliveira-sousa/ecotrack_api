class AddModelInTruck < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_trucks, :model, :string, null: false
  end
end
