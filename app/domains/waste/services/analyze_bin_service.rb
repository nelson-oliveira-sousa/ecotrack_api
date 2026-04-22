# app/domains/waste/services/analyze_bin_service.rb

module Waste
  module Services
    class AnalyzeBinService
      def self.call(bin)
        # 1. Coleta o histórico (Readings) para dar contexto à IA
        # Pegamos os últimos 10 registros para a IA entender a tendência (velocidade)
        history_data = bin.readings.last(10).map do |r|
          "#{r.created_at.strftime('%H:%M')}: #{r.level}%"
        end.join(", ")

        # 2. Monta o Prompt
        # Sendo específico sobre o formato JSON para o Gemini 2.5 Flash-Lite
        prompt = <<~PROMPT
          Você é um especialista em logística urbana.
          Analise o histórico de enchimento desta lixeira inteligente: #{history_data}.
          Nível atual: #{bin.level}%.

          Responda obrigatoriamente no formato JSON:
          {
            "previsao_cheia_em_minutos": integer,
            "analise": "string curta com a tendência"
          }
        PROMPT

        # 3. Chama a IA usando o Adapter com o perfil de análise rápida
        response = Ai::GeminiClient.generate(prompt, purpose: :fast_analysis)

        # Guard clause: Se a API cair ou o JSON vier inválido, não quebramos o processo
        return if response.nil?

        # 4. Atualiza os campos de predição no Bin
        # Usamos update! para garantir que as validações passem
        bin.update!(
          ai_prediction: response["analise"],
          predicted_full_at: Time.current + response["previsao_cheia_em_minutos"].to_i.minutes,
          last_analysis_at: Time.current
        )
      rescue StandardError => e
        Rails.logger.error "❌ Erro no AnalyzeBinService para Bin ##{bin.id}: #{e.message}"
      end
    end
  end
end
