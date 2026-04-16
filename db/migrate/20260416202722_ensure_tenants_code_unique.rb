# No terminal: rails generate migration EnsureTenantsCodeUnique
class EnsureTenantsCodeUnique < ActiveRecord::Migration[8.0]
  def change
    # Garante que o índice único existe e remove qualquer índice antigo que possa causar conflito
    remove_index :tenants, :code if index_exists?(:tenants, :code)
    add_index :tenants, :code, unique: true
  end
end
