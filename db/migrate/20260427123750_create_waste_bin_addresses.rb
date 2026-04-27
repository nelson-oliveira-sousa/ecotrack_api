class CreateWasteBinAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :waste_bin_addresses do |t|
      t.references :waste_bin, null: false, foreign_key: true
      t.string :address
      t.string :number
      t.string :neighborhood
      t.string :city
      t.string :state
      t.string :zip_code

      t.timestamps
    end
  end
end
