class FixWasteBinsTenantLink < ActiveRecord::Migration[8.0]
  def change
    # 1. Limpa o rastro da coluna antiga
    remove_column :waste_bins, :tenant_slug, :string if column_exists?(:waste_bins, :tenant_slug)

    # 2. Adiciona a referência permitindo NULL temporariamente
    add_reference :waste_bins, :tenant, null: true, foreign_key: true, index: true

    # 3. Vincula as lixeiras existentes ao tenant correto (Guaiçara)
    up_only do
      # Buscamos o tenant que você já validou antes
      tenant = Tenant.find_by(slug: 'guaicara-sp') || Tenant.first

      if tenant
        # Update direto no banco para evitar disparar validações de model
        execute "UPDATE waste_bins SET tenant_id = #{tenant.id}"
      else
        # Se não houver nenhum tenant, melhor limpar as lixeiras de teste
        execute "DELETE FROM waste_bins"
      end
    end

    # 4. Agora sim, com tudo preenchido, travamos o NOT NULL
    change_column_null :waste_bins, :tenant_id, false
  end
end
