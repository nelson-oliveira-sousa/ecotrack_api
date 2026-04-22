class MqttMessage < ApplicationRecord
  # Adicionamos 'prefix: true' para evitar conflito com métodos internos do Rails
  # Agora os métodos serão: message.status_new?, message.status_processing?, etc.
  enum :status, {
    new: "new",
    processing: "processing",
    processed: "processed",
    failed: "failed"
  }, prefix: true, default: :new

  validates :event_id, presence: true, uniqueness: true
  validates :topic, presence: true
  validates :payload, presence: true

  # O scope também precisa ser ajustado se você for usar o nome do enum
  scope :ready_for_processing, -> {
    status_new # Usa o scope gerado pelo prefixo
      .where("next_attempt_at IS NULL OR next_attempt_at <= ?", Time.current)
      .order(created_at: :asc)
  }

  def payload
    super || {}
  end
end
