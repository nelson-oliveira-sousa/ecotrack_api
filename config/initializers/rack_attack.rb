class Rack::Attack
  # 1. Throttle por IP (Login e Troca de Senha)
  throttle("identity/ip", limit: 5, period: 20.seconds) do |req|
    if req.post? && (req.path == "/api/v1/login" || req.path == "/api/v1/update_password")
      req.ip
    end
  end

  # 2. Throttle por E-mail (Proteção contra IPs rotativos)
  throttle("identity/email", limit: 5, period: 1.minute) do |req|
    if req.post? && req.path == "/api/v1/login"
      req.params["email"].to_s.downcase.gsub(/\s+/, "")
    end
  end

  # 3. Resposta padronizada para o App
  self.throttled_responder = lambda do |env|
    [ 429,
      { "Content-Type" => "application/json" },
      [ { error: "Muitas tentativas. Tente novamente em alguns minutos.", code: "TOO_MANY_REQUESTS" }.to_json ]
    ]
  end
end
