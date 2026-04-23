class MqttMessage < ApplicationRecord
  # 🔥 ESSENCIAL: Sem isso, o Rails não sabe quem é o dono da mensagem
  belongs_to :tenant

  enum :status, {
    new: "new",
    processing: "processing",
    processed: "processed",
    failed: "failed"
  }, prefix: true, default: :new

  validates :event_id, presence: true, uniqueness: true
  validates :topic, presence: true
  validates :payload, presence: true

  scope :ready_for_processing, -> {
    status_new
      .where("next_attempt_at IS NULL OR next_attempt_at <= ?", Time.current)
      .order(created_at: :asc)
  }

  def payload
    super || {}
  end
end
