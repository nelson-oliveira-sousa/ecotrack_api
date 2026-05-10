class AddLastErrorToMqttMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :mqtt_messages, :last_error, :text
  end
end
