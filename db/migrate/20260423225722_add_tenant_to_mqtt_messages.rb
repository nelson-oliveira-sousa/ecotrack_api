class AddTenantToMqttMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :mqtt_messages, :tenant, null: false, foreign_key: true
  end
end
