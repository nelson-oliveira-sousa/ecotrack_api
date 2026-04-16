class CreateTenantProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :tenant_profiles do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :document
      t.string :contact_email
      t.string :contact_phone

      t.timestamps
    end
    add_index :tenant_profiles, :document
  end
end
