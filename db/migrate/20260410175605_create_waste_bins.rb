class CreateWasteBins < ActiveRecord::Migration[8.1]
  def change
    create_table :waste_bins do |t|
      t.string :tenant_slug
      t.string :label
      t.integer :level
      t.string :status
      t.decimal :latitude
      t.decimal :longitude

      t.timestamps
    end
  end
end
