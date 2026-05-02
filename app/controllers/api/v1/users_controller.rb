module Api
  module V1
    class UsersController < Api::V1::ApiController
      before_action :require_admin!
      before_action :set_user, only: [ :show, :update, :destroy ]

      # GET /api/v1/users
      def index
        users = Current.tenant.users
        render json: { users: Identity::Serializers::UserSerializer.render(users) }, status: :ok
      end

      def create
        result = Identity::Services::UserRegistration.call(
          tenant: Current.tenant,
          params: user_params
        )

        if result.success?
          render json: {
            message: "Usuário criado com sucesso!",
            user: Identity::Serializers::UserSerializer.render(
              result.user,
              include_force_change: true,
              temporary_password: result.temporary_password
            )
          }, status: :created
        else
          render json: {
            error: "Erro ao criar usuário!",
            details: result.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @user.update(user_update_params)
          render json: {
            message: "Dados atualizados com sucesso.",
            user: Identity::Serializers::UserSerializer.render(@user)
          }, status: :ok
        else
          render json: { error: "Falha ao atualizar dados.", details: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @user.update(status: :inactive)
          render json: { message: "Usuário desativado com sucesso." }, status: :ok
        else
          render json: { error: "Falha ao desativar usuário.", details: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def user_update_params
        # Impede que a senha seja alterada acidentalmente na edição de perfil
        params.require(:user).permit(:name, :email, :role)
      end
    end
  end
end
