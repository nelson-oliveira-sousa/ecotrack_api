class RenameDevEuiToSensorIdInWasteBins < ActiveRecord::Migration[8.1]
  def change
    # Renomeia a coluna e, por consequência, o Rails atualizará o índice associado
    rename_column :waste_bins, :dev_eui, :sensor_id
  end
end
