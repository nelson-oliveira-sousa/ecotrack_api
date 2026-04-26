class AddBatteryToWasteReadings < ActiveRecord::Migration[8.1]
  def change
    add_column :waste_readings, :battery, :integer
  end
end
