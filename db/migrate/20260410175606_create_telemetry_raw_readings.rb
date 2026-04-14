class CreateTelemetryRawReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :telemetry_raw_readings do |t|
      t.references :waste_bin, null: false, foreign_key: true
      t.integer :level
      t.jsonb :raw_payload

      t.timestamps
    end
  end
end
