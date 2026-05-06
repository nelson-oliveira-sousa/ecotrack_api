class AddEquipmentStatusToWasteBins < ActiveRecord::Migration[8.1]
  def change
    add_column :waste_bins, :equipment_status, :string, default: "online"
  end
end
