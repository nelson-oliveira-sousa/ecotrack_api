class FixUsersTable < ActiveRecord::Migration[8.0]
  def change
    # 1. Remove a coluna antiga (se existir)
    remove_column :users, :tenant_slug, :string if column_exists?(:users, :tenant_slug)

    # 2. Adiciona a referência permitindo NULL por enquanto
    add_reference :users, :tenant, null: true, foreign_key: true, index: true

    # 3. Código de transição: Vincula usuários existentes ao primeiro Tenant encontrado
    # Isso evita o erro de NotNullViolation
    up_only do
      first_tenant = Tenant.first
      if first_tenant
        User.update_all(tenant_id: first_tenant.id)
      end
    end

    # 4. Agora que todos têm um tenant_id, aplicamos a trava de NOT NULL
    change_column_null :users, :tenant_id, false
  end
end
