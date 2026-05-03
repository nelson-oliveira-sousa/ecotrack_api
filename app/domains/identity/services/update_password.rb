# app/domains/identity/services/update_password.rb
module Identity
  module Services
    class UpdatePassword < ApplicationService
      def initialize(user:, current_password:, new_password:, token:)
        @user = user
        @current_password = current_password
        @new_password = new_password
        @token = token
      end

      def call
        # 1. Validação de Regra de Negócio
        unless @user.authenticate(@current_password)
          return failure("Senha atual incorreta.", :unauthorized)
        end

        # 2. Transação / Persistência
        if @user.update(password: @new_password, force_password_change: false)

          # 3. Efeito Colateral Isolado
          Identity::Services::Revoker.call(@token) if @token.present?

          success({ message: "Senha atualizada com sucesso. Por segurança, faça login novamente." })
        else
          failure(@user.errors.full_messages, :unprocessable_entity)
        end
      rescue StandardError => e
        failure("Erro ao processar a troca de senha: #{e.message}", :internal_server_error)
      end
    end
  end
end
