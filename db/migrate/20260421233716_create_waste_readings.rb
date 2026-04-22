class CreateWasteReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :waste_readings do |t|
      # Ajustamos aqui para apontar para a tabela correta: waste_bins
      t.references :bin, null: false, foreign_key: { to_table: :waste_bins }
      t.integer :level
      t.string :status

      t.timestamps
    end
  end
end
