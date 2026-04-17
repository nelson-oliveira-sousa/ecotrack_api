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
        # 1. Recuperamos o "RG" do ambiente enviado pelo Juan (Front)
        header_tenant_code = request.headers["X-Tenant-Code"]

        # 2. Decodificamos o Token (que já traz o user_id e jti)
        decoded = Identity::Services::TokenManager.decode(extract_token)

        if decoded
          @current_user = User.find_by(id: decoded["user_id"])

          if @current_user
            # 3. Sincronizamos o contexto global
            Current.user = @current_user
            Current.tenant = @current_user.tenant # Aqui pegamos o objeto Tenant real do banco

            # 🔥 A VALIDAÇÃO CRUCIAL:
            # O Code do header precisa ser igual ao Code do Tenant que é dono desse usuário.
            # Se o Juan tentar usar o token da prefeitura A com o Code da prefeitura B, o sistema barra.
            if header_tenant_code.present? && Current.tenant.code != header_tenant_code
              return render json: { error: "Inconsistência de Tenant. Acesso negado." }, status: :forbidden
            end
          end
        end

        render_unauthorized unless @current_user && Current.tenant
      end

      def extract_token
        # O token deve ser enviado no header Authorization
        header = request.headers["Authorization"]
        return nil if header.blank?

        # O padrão é "Bearer <token>". O split separa no espaço e pegamos a última parte.
        header.split(" ").last
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

      def render_unauthorized
        render json: {
          error: "Acesso negado. Token inválido, expirado ou revogado."
        }, status: :unauthorized
      end

      def render_forbidden(message = "Acesso restrito.")
        render json: { error: message }, status: :forbidden
      end
    end
  end
end
