# app/domains/waste/services/analyze_bin_service.rb

module Waste
  module Services
    class AnalyzeBinService < ApplicationService
      def initialize(bin)
        @bin = bin
      end

      def call
        history_data = bin.readings.last(10).map do |r|
          "#{r.created_at.strftime('%H:%M')}: #{r.level}%"
        end.join(", ")

        prompt = <<~PROMPT
          Você é um motorista de caminhão de lixo especialista em rotas otimizadas.
          CONTEXTO:
          - Lixeira ID: #{bin.id} (#{bin.label})
          - Histórico (Hora: Nível): #{history_data}
          - Nível Atual: #{bin.level}%
          - Horário de agora: #{Time.current.strftime('%H:%M')}

          TAREFA:
          1. Analise a velocidade de enchimento.
          2. Preveja quantos minutos faltam para atingir 100%. Se já estiver cheia ou diminuindo, retorne 0.
          3. Crie uma análise de uma frase para o operador.

          RETORNO OBRIGATÓRIO EM JSON:
          {
            "previsao_cheia_em_minutos": integer,
            "analise": "string"
          }
        PROMPT

        response = Ai::GeminiClient.generate(prompt, purpose: :fast_analysis)

        return failure("IA não retornou uma resposta válida.", :bad_gateway) if response.nil?

        bin.update!(
          ai_prediction: response["analise"],
          predicted_full_at: Time.current + response["previsao_cheia_em_minutos"].to_i.minutes,
          last_analysis_at: Time.current
        )

        success({ bin: bin })
      rescue StandardError => e
        Rails.logger.error("Erro no AnalyzeBinService para Bin ##{bin.id}: #{e.message}")
        failure("Erro ao analisar lixeira: #{e.message}", :internal_server_error)
      end

      private

      attr_reader :bin
    end
  end
end
