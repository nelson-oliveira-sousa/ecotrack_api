class AddDocumentFieldsToFleetTrucks < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_trucks, :renavam, :string
    add_column :fleet_trucks, :manufacture_year, :integer
    add_column :fleet_trucks, :document_expiration_date, :date
  end
end
