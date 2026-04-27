class RefactorWasteBinsForChirpStack < ActiveRecord::Migration[8.1]
  def change
    # Remove as colunas antigas
    remove_column :waste_bins, :latitude, :float # ou :string, dependendo do seu tipo original
    remove_column :waste_bins, :longitude, :float

    # Adiciona o identificador LoRaWAN
    add_column :waste_bins, :dev_eui, :string
    add_index :waste_bins, :dev_eui, unique: true
  end
end
