class CreateMqttMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :mqtt_messages do |t|
      # 1. Idempotência: Chave única para evitar processar a mesma mensagem 2x
      t.string :event_id, null: false

      # 2. Dados da Mensagem
      t.string :topic, null: false
      t.jsonb :payload, default: {}, null: false

      # 3. Máquina de Estados (new, processing, processed, failed)
      t.string :status, default: "new", null: false
      t.integer :retry_count, default: 0

      # 4. Controle de Tempo e Auditoria
      t.datetime :processing_at
      t.datetime :processed_at
      t.datetime :next_attempt_at

      t.timestamps
    end

    # --- ÍNDICES DE ALTA PERFORMANCE ---

    # Garante que, se o MQTT repetir a mensagem, o banco barra o insert duplicado
    add_index :mqtt_messages, :event_id, unique: true

    # Índice essencial para o Worker: permite achar mensagens 'new'
    # instantaneamente, mesmo com milhões de registros.
    add_index :mqtt_messages, [ :status, :next_attempt_at, :created_at ],
              name: "idx_mqtt_messages_worker_flow"
  end
end
