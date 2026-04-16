# db/migrate/[TIMESTAMP]_add_code_to_tenants.rb
class AddCodeToTenants < ActiveRecord::Migration[8.0]
  def change
    add_column :tenants, :code, :string
    add_index :tenants, :code, unique: true
  end
end
