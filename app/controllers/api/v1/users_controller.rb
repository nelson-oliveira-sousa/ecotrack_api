# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < Api::V1::ApiController
      before_action :require_admin!
      before_action :set_user, only: [ :show, :update, :destroy ]

      # GET /api/v1/users
      def index
        users = Current.tenant.users
        users = users.where(role: params[:role]) if params[:role].present?

        data = Identity::Serializers::UserSerializer.render_collection(users)
        render_result(Result.new(success: true, data: data))
      end

      # GET /api/v1/users/:id
      # Adicionado para resolver o erro AbstractController::ActionNotFound
      def show
        data = Identity::Serializers::UserSerializer.render(@user)
        render_result(Result.new(success: true, data: data))
      end

      # POST /api/v1/users
      def create
        result = Identity::Services::UserRegistration.call(
          tenant: Current.tenant,
          user_params: user_params
        )

        if result.success?
          serialized_data = Identity::Serializers::UserSerializer.render(
            result.data[:user],
            include_force_change: true,
            temporary_password: result.data[:temp_password]
          )
          render_result(Result.new(success: true, data: serialized_data, status: :created))
        else
          render_result(result)
        end
      end

      # PATCH/PUT /api/v1/users/:id
      def update
        if @user.update(user_params) # Chamada corrigida
          data = Identity::Serializers::UserSerializer.render(@user)
          render_result(Result.new(success: true, data: data))
        else
          render_result(Result.new(success: false, error: @user.errors.full_messages, status: :unprocessable_entity))
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
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

      # Renomeado de user_update_params para user_params para bater com as chamadas acima
      def user_params
        params.require(:user).permit(
          :name, :email, :role,
          :cnh_number, :cnh_category, :cnh_expiration_date # Novos campos liberados
        )
      end
    end
  end
end
