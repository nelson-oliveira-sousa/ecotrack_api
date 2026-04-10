# app/domains/identity/services/revoker.rb
module Identity
  module Services
    class Revoker
      def self.call(token)
        # Decodificamos sem validar a expiração (se já expirou, não precisamos revogar de novo)
        decoded = JWT.decode(token, TokenManager::SECRET_KEY, false)[0]

        jti = decoded["jti"]
        exp = Time.at(decoded["exp"])

        # Salva no banco de dados
        RevokedToken.find_or_create_by!(jti: jti) do |revoked|
          revoked.exp = exp
        end

        { success: true }
      rescue JWT::DecodeError
        { success: false, error: "Token malformado" }
      end
    end
  end
end
