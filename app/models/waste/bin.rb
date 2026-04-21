# app/models/waste/bin.rb
module Waste
  class Bin < ApplicationRecord
    # Relacionamento Sênior
    belongs_to :tenant

    has_many :raw_readings,
             class_name: "Telemetry::RawReading",
             foreign_key: "waste_bin_id",
             dependent: :destroy

    before_save :sync_status, if: :level_changed?

    enum :status, {
      normal: "normal",
      warning: "warning",
      critical: "critical",
      offline: "offline"
    }, default: :normal

    # Validações
    validates :label, presence: true
    validates :tenant, presence: true

    # Unicidade da lixeira DENTRO da prefeitura específica
    validates :label, uniqueness: { scope: :tenant_id }

    private

    def sync_status
      self.status = Waste::BinStatusResolver.call(level)
    end
  end
end
