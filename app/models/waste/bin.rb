# app/models/waste/bin.rb
module Waste
  class Bin < ApplicationRecord
    # Relacionamento Sênior
    belongs_to :tenant

    has_many :raw_readings,
             class_name: "Telemetry::RawReading",
             foreign_key: "waste_bin_id",
             dependent: :destroy

    has_many :readings, class_name: "Waste::Reading", dependent: :destroy

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

    def analysis_needed?
      # 1. Só analisa se estiver acima do limite crítico
      return false if level < 80

      # 2. Só analisa se nunca foi analisada OU se a última análise foi há mais de 30 min
      # Isso evita criar uma fila gigante de Jobs desnecessários
      last_analysis_at.nil? || last_analysis_at < 30.minutes.ago
    end
  end
end
