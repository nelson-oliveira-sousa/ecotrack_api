class Rack::Attack
  # Bloqueia o IP se ele tentar logar mais de 5 vezes em 20 segundos
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/v1/login" && req.post?
      req.ip
    end
  end

  # (Opcional) Bloqueia por e-mail, caso o atacante use IPs rotativos para atacar a mesma conta
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/v1/login" && req.post?
      req.params["email"].to_s.downcase.gsub(/\s+/, "")
    end
  end
end
