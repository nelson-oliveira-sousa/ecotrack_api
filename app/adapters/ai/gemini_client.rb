module Ai
  class GeminiClient
    BASE_URL = "https://generativelanguage.googleapis.com"

    def self.generate(prompt, purpose: :general_purpose)
      new(purpose).generate(prompt)
    end

    def initialize(purpose)
      @model_code = Ai::ModelRegistry.get(purpose)
    end

    def generate(prompt)
      # Endpoint v1beta suporta os modelos mais recentes como o Gemini 3 Flash
      response = connection.post("/v1beta/models/#{@model_code}:generateContent") do |req|
        req.body = {
          contents: [ { parts: [ { text: prompt } ] } ],
          generationConfig: {
            # Garante que a IA tente responder em JSON sempre que possível
            response_mime_type: "application/json"
          }
        }.to_json
      end

      if response.success?
        parse_response(response.body)
      else
        handle_error(response)
      end
    rescue Faraday::Error => e
      Rails.logger.error("🔥 Erro Crítico de Rede no GeminiClient: #{e.message}")
      nil
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.headers["Content-Type"] = "application/json"
        f.headers["x-goog-api-key"] = api_key
        f.request :json
        f.adapter Faraday.default_adapter

        # Opcional: f.response :logger se quiser debugar no terminal
      end
    end

    def api_key
      ENV["GEMINI_API_KEY"] || Rails.application.credentials.gemini_api_key
    end

    def parse_response(body)
      # Garante que o body seja um Hash
      data = body.is_a?(String) ? JSON.parse(body) : body

      # Navega na estrutura da API do Gemini para pegar o texto
      raw_text = data.dig("candidates", 0, "content", "parts", 0, "text")
      return nil unless raw_text

      # Limpeza de Markdown: Se a IA enviar ```json { ... } ```, nós limpamos.
      clean_json = raw_text.gsub(/```json|```/, "").strip
      JSON.parse(clean_json)
    rescue JSON::ParserError => e
      Rails.logger.error("🧱 Falha ao parsear JSON da IA: #{e.message} | Texto: #{raw_text}")
      nil
    end

    def handle_error(response)
      Rails.logger.error("❌ Erro na API Gemini [#{@model_code}]: #{response.status} - #{response.body}")
      nil
    end
  end
end
