# db/migrate/YYYYMMDDHHMMSS_create_alerts.rb
class CreateAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :alerts do |t|
      t.string :title, null: false
      t.string :message, null: false

      # Defaults baseados nos nossos enums:
      # severity: 1 (warning), status: 0 (pending), category: 0 (bin_full)
      t.integer :severity, default: 1, null: false
      t.integer :status, default: 0, null: false
      t.integer :category, default: 0, null: false

      # Polymorphic: cria alertable_type e alertable_id
      t.references :alertable, polymorphic: true, null: true

      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end

    # Índice para deixar o Polling/Stream muito rápido quando buscar alertas pendentes
    add_index :alerts, [ :tenant_id, :status ]
  end
end
