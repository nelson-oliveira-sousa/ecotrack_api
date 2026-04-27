class AddCoordinatesToWasteBinAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :waste_bin_addresses, :latitude, :decimal, precision: 10, scale: 6
    add_column :waste_bin_addresses, :longitude, :decimal, precision: 10, scale: 6
  end
end
