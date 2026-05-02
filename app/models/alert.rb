# app/models/alert.rb
class Alert < ApplicationRecord
  belongs_to :tenant
  belongs_to :alertable, polymorphic: true, optional: true

  enum :severity, { info: 0, warning: 1, critical: 2 }, default: :warning
  enum :status, { pending: 0, resolved: 1 }, default: :pending
  enum :category, { bin_full: 0, low_battery: 1, truck_issue: 2, system: 3 }

  after_create_commit :broadcast_alert_to_stream

  private

  def broadcast_alert_to_stream
    channel = "alerts_tenant_#{self.tenant_id}"
    payload = self.as_json(only: [ :id, :category, :severity, :title, :message, :created_at ]).to_json

    # Usa a conexão com o banco para disparar o NOTIFY nativo do Postgres
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      # Escapa o JSON para evitar quebrar a query SQL
      escaped_payload = connection.raw_connection.escape_string(payload)
      connection.execute("NOTIFY #{channel}, '#{escaped_payload}'")
    end
  end
end
