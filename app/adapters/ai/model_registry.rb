# app/adapters/ai/model_registry.rb

module Ai
  module ModelRegistry
    # Mapeamento dos modelos disponíveis conforme a capacidade
    MODELS = {
      # O "pau para toda obra": Rápido e multimodal
      general_purpose: "gemini-3-flash",

      # O "atleta de elite": Baixíssima latência e custo
      fast_analysis:   "gemini-2.5-flash-lite",

      # O "olho clínico": Especialista em imagens
      vision:          "gemini-3-flash-image", # Nano Banana 2

      # O "diretor": Geração de vídeo
      logistics_video: "veo",

      # O "maestro": Áudio e notificações
      audio_alerts:    "lyria-3"
    }.freeze

    def self.get(key)
      MODELS[key] || MODELS[:general_purpose]
    end
  end
end
