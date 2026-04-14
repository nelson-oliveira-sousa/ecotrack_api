# app/domains/telemetry/services/ingest_reading.rb
module Telemetry
  module Services
    class IngestReading
      def self.call(valid_data, raw_payload)
        # 1. Tenta achar a lixeira alvo
        bin = Waste::Bin.find_by(tenant_slug: valid_data[:tenant_slug], label: valid_data[:bin_label])

        return { success: false, error: "Lixeira [#{valid_data[:bin_label]}] não encontrada na base." } unless bin

        # 2. Abre uma Transação no Banco (Tudo ou Nada)
        ActiveRecord::Base.transaction do
          # Salva a "Caixa Preta" para o dashboard do prefeito
          Telemetry::RawReading.create!(
            waste_bin: bin,
            level: valid_data[:level],
            raw_payload: raw_payload
          )

          # Atualiza a Lixeira Física e define a cor no mapa
          new_status = determine_status(valid_data[:level])
          bin.update!(level: valid_data[:level], status: new_status)
        end

        { success: true, bin: bin }
      rescue StandardError => e
        { success: false, error: "Erro interno no banco: #{e.message}" }
      end

      # A Regra de Negócio das Cores (Pode virar tabela no futuro)
      def self.determine_status(level)
        case level
        when 0..49 then "normal"     # Verde
        when 50..79 then "warning"   # Amarelo
        else "critical"              # Vermelho (Vai chamar o caminhão)
        end
      end
    end
  end
end
