module Waste
  class Bin < ApplicationRecord
    has_many :raw_readings, class_name: "Telemetry::RawReading", foreign_key: "waste_bin_id", dependent: :destroy

    enum :status, { normal: "normal", warning: "warning", critical: "critical", offline: "offline" }

    validates :tenant_slug, :label, presence: true
    validates :label, uniqueness: { scope: :tenant_slug }
  end
end
