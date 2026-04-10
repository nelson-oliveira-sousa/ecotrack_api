# app/domains/identity/services/token_manager.rb
module Identity
  module Services
    class TokenManager
      SECRET_KEY = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base

      def self.encode(payload, exp = 24.hours.from_now)
        payload[:exp] = exp.to_i
        # 1. GERA UM ID ÚNICO PARA ESTE TOKEN (O "Chassi")
        payload[:jti] = SecureRandom.uuid

        JWT.encode(payload, SECRET_KEY)
      end

      def self.decode(token)
        decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: "HS256" })[0]

        # 2. A CHECAGEM DE SEGURANÇA NO POSTGRES
        # Se o JTI estiver na tabela de revogados, o token é considerado nulo (inválido)
        return nil if RevokedToken.exists?(jti: decoded["jti"])

        HashWithIndifferentAccess.new(decoded)
      rescue JWT::DecodeError, JWT::ExpiredSignature
        nil
      end
    end
  end
end
