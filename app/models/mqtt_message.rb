class MqttMessage < ApplicationRecord
  # 1. Máquina de Estados: Usamos strings para os enums para facilitar
  # a leitura direta no banco de dados (PgWeb).
  enum :status, {
    new: "new",             # Acabou de chegar e aguarda o Worker
    processing: "processing", # Sendo processada por um Worker (travada)
    processed: "processed",   # Finalizada com sucesso
    failed: "failed"          # Esgotou as tentativas (Dead Letter Queue)
  }, default: :new

  # 2. Validações: Blindagem dos dados
  validates :event_id, presence: true, uniqueness: true
  validates :topic, presence: true
  validates :payload, presence: true

  # 3. Scope de Especialista: O "Cérebro" da Fila
  # Esse scope garante que o Worker pegue apenas o que deve ser processado agora.
  scope :ready_for_processing, -> {
    where(status: :new)
      .where("next_attempt_at IS NULL OR next_attempt_at <= ?", Time.current)
      .order(created_at: :asc)
  }

  # 4. Helper para JSONB
  # O Rails já trata jsonb como um Hash, mas isso garante que nunca seja nil.
  def payload
    super || {}
  end
end
