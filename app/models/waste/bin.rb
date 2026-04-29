module Waste
  class Bin < ApplicationRecord
    # Relacionamentos
    belongs_to :tenant

    # Nova relação com a tabela de endereço separada
    has_one :bin_address,
            class_name: "Waste::BinAddress",
            foreign_key: :waste_bin_id,
            dependent: :destroy,
            inverse_of: :waste_bin

    has_many :raw_readings,
             class_name: "Telemetry::RawReading",
             foreign_key: "waste_bin_id",
             dependent: :destroy

    has_many :readings, class_name: "Waste::Reading", dependent: :destroy

    # Permite criar/atualizar o endereço junto com a lixeira
    accepts_nested_attributes_for :bin_address, update_only: true

    # Callbacks
    before_save :sync_status, if: :level_changed?

    enum :status, {
      normal: "normal",
      warning: "warning",
      critical: "critical",
      collected: "collected",
      offline: "offline"
    }, default: :normal

    # Validações Sênior
    validates :label, presence: true
    validates :tenant, presence: true

    validates :sensor_id, presence: true, uniqueness: true

    # Unicidade da lixeira por label dentro da mesma prefeitura
    validates :label, uniqueness: { scope: :tenant_id }

    # Delegação para facilitar o acesso ao endereço formatado
    def full_address
      return "Endereço não cadastrado" unless bin_address

      [
        bin_address.address,
        bin_address.number,
        bin_address.neighborhood,
        "#{bin_address.city}/#{bin_address.state}"
      ].compact.join(", ")
    end

    def sync_status
      self.status = Waste::BinStatusResolver.call(level)
    end

    def analysis_needed?
      return false if level < 80
      last_analysis_at.nil? || last_analysis_at < 30.minutes.ago
    end

    def last_collection
      readings.where(status: "collected").order(created_at: :desc).first&.created_at
    end
  end
end
