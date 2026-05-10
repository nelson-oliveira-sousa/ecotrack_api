# app/controllers/api/v1/api_controller.rb
module Api
  module V1
    class ApiController < ApplicationController
      include ApiResponder

      before_action :authorize_request
      before_action :check_user_status!
      before_action :enforce_password_change!

      private

      def authorize_request
        header_tenant_code = request.headers["X-Tenant-Code"]
        decoded = Identity::Services::TokenManager.decode(extract_token)

        if decoded
          @current_user = User.find_by(id: decoded["user_id"])

          if @current_user
            Current.user = @current_user
            Current.tenant = @current_user.tenant
            @current_tenant = Current.tenant

            if header_tenant_code.present? && Current.tenant.code != header_tenant_code
              return render_forbidden("Inconsistência de Tenant. Acesso negado.")
            end
          end
        end

        render_unauthorized unless @current_user && Current.tenant
      end

      def check_user_status!
        if current_user && !current_user.active?
          render_forbidden("Sua conta está desativada ou suspensa. Contate o administrador.")
        end
      end

      def enforce_password_change!
        return unless current_user

        if current_user.force_password_change?
          allowed_paths = [
            "/api/v1/update_password",
            "/api/v1/logout"
          ]

          unless allowed_paths.include?(request.path)
            render_result(Result.new(
              success: false,
              error: "Troca de senha obrigatória no primeiro acesso.",
              data: { code: "MUST_CHANGE_PASSWORD" },
              status: :forbidden
            ))
          end
        end
      end

      def require_superadmin_or_vendedor!
        unless Current.user && %w[superadmin vendedor].include?(Current.user.role)
          render_forbidden("Acesso negado. Apenas Superadmins e Vendedores podem provisionar novas prefeituras.")
        end
      end

      def extract_token
        header = request.headers["Authorization"]
        return nil if header.blank?

        header.split(" ").last
      end

      def current_user
        @current_user
      end

      def current_tenant
        @current_tenant
      end

      def require_admin!
        unless current_user&.admin?
          render_forbidden("Acesso restrito. Privilégios de administrador necessários.")
        end
      end

      def require_manager!
        unless current_user&.admin? || current_user&.manager?
          render_forbidden("Acesso restrito. Privilégios de gerente ou administrador necessários.")
        end
      end

      def render_unauthorized
        render_result(Result.new(
          success: false,
          error: "Acesso negado. Token inválido, expirado ou revogado.",
          status: :unauthorized
        ))
      end

      def render_forbidden(message = "Acesso restrito.")
        render_result(Result.new(success: false, error: message, status: :forbidden))
      end
    end
  end
end
