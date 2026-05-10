# app/domains/identity/services/revoker.rb
module Identity
  module Services
    class Revoker < ApplicationService
      def initialize(token)
        @token = token
      end

      def call
        decoded = JWT.decode(token, TokenManager::SECRET_KEY, false)[0]

        jti = decoded["jti"]
        exp = Time.at(decoded["exp"])

        RevokedToken.find_or_create_by!(jti: jti) do |revoked|
          revoked.exp = exp
        end

        success
      rescue JWT::DecodeError
        failure("Token malformado", :unprocessable_entity)
      end

      private

      attr_reader :token
    end
  end
end
