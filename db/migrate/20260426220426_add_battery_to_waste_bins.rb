class AddBatteryToWasteBins < ActiveRecord::Migration[8.1]
  def change
    add_column :waste_bins, :battery, :integer
  end
end
