# app/domains/telemetry/services/ingest_reading.rb
module Telemetry
  module Services
    class IngestReading < ApplicationService
      # Utilizamos named parameters para maior clareza na injeção de dependências
      def initialize(valid_data:, raw_payload:)
        @valid_data = valid_data
        @raw_payload = raw_payload
      end

      def call
        # 1. Tenta achar a lixeira alvo
        bin = Waste::Bin.find_by(
          tenant_slug: @valid_data[:tenant_slug],
          label: @valid_data[:bin_label]
        )

        # ❌ Se falhar, usa o nosso helper de failure com o status HTTP correto
        unless bin
          return failure("Lixeira [#{@valid_data[:bin_label]}] não encontrada na base.", :not_found)
        end

        # 2. Abre uma Transação no Banco (Tudo ou Nada)
        ActiveRecord::Base.transaction do
          # Salva a "Caixa Preta"
          Telemetry::RawReading.create!(
            waste_bin: bin,
            level: @valid_data[:level],
            raw_payload: @raw_payload
          )

          # 🧠 Regra de Negócio: Delegamos para o Model/Domain apropriado
          # Se não quiser usar a classe externa ainda, mantenha o método privado no service.
          # Mas o ideal é algo como:
          # new_status = Waste::BinStatusResolver.resolve(@valid_data[:level])
          new_status = determine_status(@valid_data[:level])

          bin.update!(level: @valid_data[:level], status: new_status)
        end

        # ✅ Retorna sucesso com o padrão Result
        success({ bin: bin }, :ok)
      rescue StandardError => e
        # Captura erros de banco (ex: deadlock) e devolve estruturado
        failure("Erro interno no banco: #{e.message}", :internal_server_error)
      end

      private

      # Se você ainda não transferiu isso para o BinStatusResolver,
      # mantenha como PRIVATE para não vazar a regra.
      def determine_status(level)
        case level.to_i
        when 0..49 then "normal"     # Verde
        when 50..79 then "warning"   # Amarelo
        else "critical"              # Vermelho
        end
      end
    end
  end
end
