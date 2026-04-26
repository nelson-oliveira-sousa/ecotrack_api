class AllowNullTenantIdOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :tenant_id, true
  end
end
