# db/migrate/20260414235803_add_constraints_to_tenants_code.rb
class AddConstraintsToTenantsCode < ActiveRecord::Migration[8.0]
  def change
    # 1. Só altera o NULL se ele ainda for anulável (evita erro de repetição)
    change_column_null :tenants, :code, false

    # 2. Remove o índice antigo se ele já existir (para evitar o erro PG::DuplicateTable)
    remove_index :tenants, :code if index_exists?(:tenants, :code)

    # 3. Adiciona o índice único "do zero"
    add_index :tenants, :code, unique: true
  end
end
