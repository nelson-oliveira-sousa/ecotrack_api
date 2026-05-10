class AddSensorKeyToWasteBins < ActiveRecord::Migration[8.1]
  def change
    add_column :waste_bins, :sensor_key, :string
    add_index :waste_bins, :sensor_key, unique: true
  end
end
