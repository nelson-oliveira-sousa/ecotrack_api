# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < Api::V1::ApiController
      before_action :require_admin!
      before_action :set_user, only: [ :update, :destroy ]

      # GET /api/v1/users
      def index
        users = Current.tenant.users
        users = users.where(role: params[:role]) if params[:role].present?

        data = Identity::Serializers::UserSerializer.render_collection(users)
        # Usando o padrão Result de forma mais semântica
        render_result(Result.new(success: true, data: data))
      end

      # POST /api/v1/users
      def create
        result = Identity::Services::UserRegistration.call(
          tenant: Current.tenant,
          user_params: user_params
        )

        return render_result(result) unless result.success?

        data = Identity::Serializers::UserSerializer.render(
          result.data[:user],
          temporary_password: result.data[:temp_password]
        )

        render_result(Result.new(success: true, data: data, status: :created))
      end

      # PATCH/PUT /api/v1/users/:id
      def update
        # Idealmente: result = Identity::Services::UserUpdate.call(user: @user, params: user_params)
        # Por agora, vamos apenas padronizar a resposta
        if @user.update(user_params)
          data = Identity::Serializers::UserSerializer.render(@user)
          render_result(Result.new(success: true, data: data))
        else
          # Usando o objeto Result para falhas também
          render_result(Result.new(success: false, error: @user.errors.full_messages, status: :unprocessable_entity))
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
        # Soft delete padronizado
        if @user.update(status: :inactive)
          render_result(Result.new(success: true, data: { message: "Usuário desativado com sucesso." }))
        else
          render_result(Result.new(success: false, error: @user.errors.full_messages, status: :unprocessable_entity))
        end
      end

      private

      def set_user
        @user = Current.tenant.users.find(params[:id])
      end

      def user_params
        params.require(:user).permit(
          :name, :email, :role,
          :cnh_number, :cnh_category, :cnh_expiration_date
        )
      end
    end
  end
end
