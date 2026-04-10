# app/controllers/api/v1/api_controller.rb
module Api
  module V1
    class ApiController < ApplicationController
      # 1. POLÍTICA DE NEGAÇÃO POR PADRÃO (Default Deny)
      # Tranca absolutamente todas as rotas que herdarem deste controller.
      # Apenas controllers específicos (como o de Login) farão o 'skip'.
      before_action :authorize_request

      private

      # 2. O MOTOR DE AUTENTICAÇÃO
      def authorize_request
        header = request.headers["Authorization"]
        token = header.split(" ").last if header

        # O nosso TokenManager já faz o trabalho pesado: decodifica e verifica
        # se o JTI está na tabela de revogados (Denylist) do Postgres.
        decoded = Identity::Services::TokenManager.decode(token)

        if decoded
          @current_user = User.find_by(id: decoded["user_id"])
          @current_tenant = decoded["tenant_slug"]
        end

        # Se o token for falso, expirado, revogado ou o usuário não existir mais:
        unless @current_user
          render json: { error: "Acesso negado. Token inválido, expirado ou revogado." }, status: :unauthorized
        end
      end

      # 3. HELPERS DE CONTEXTO
      # Deixa os dados disponíveis para os controllers filhos usarem livremente.
      def current_user
        @current_user
      end

      def current_tenant
        @current_tenant
      end

      # 4. MOTOR DE AUTORIZAÇÃO (RBAC - Role-Based Access Control)
      # Ganchos de segurança para você usar nas rotas que exigem privilégios.

      def require_admin!
        unless current_user&.admin?
          render json: { error: "Acesso restrito. Privilégios de administrador necessários." }, status: :forbidden
        end
      end

      def require_manager!
        # O Admin sempre pode fazer o que o Manager faz
        unless current_user&.admin? || current_user&.manager?
          render json: { error: "Acesso restrito. Privilégios de gerente ou administrador necessários." }, status: :forbidden
        end
      end
    end
  end
end
