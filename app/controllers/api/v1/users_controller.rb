# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < Api::V1::ApiController
      before_action :require_admin!
      before_action :set_user, only: [ :show, :update, :destroy ]

      # GET /api/v1/users
      def index
        users = Current.tenant.users
        data = Identity::Serializers::UserSerializer.render(users)

        # Envolvemos em um Result para garantir o formato do JSON de saída
        render_result(Result.new(success: true, data: data))
      end

      # POST /api/v1/users
      def create
        result = Identity::Services::UserRegistration.call(
          tenant: Current.tenant,
          user_params: user_params
        )

        if result.success?
          # O Controller (camada de apresentação) formata a saída do Service
          serialized_data = Identity::Serializers::UserSerializer.render(
            result.data[:user],
            include_force_change: true,
            temporary_password: result.data[:temp_password]
          )

          # Renderiza sucesso com os dados serializados
          render_result(Result.new(success: true, data: serialized_data, status: :created))
        else
          # Renderiza a falha repassando o Result original do Service
          render_result(result)
        end
      end

      # PATCH/PUT /api/v1/users/:id
      def update
        if @user.update(user_params)
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

      def user_update_params
        params.require(:user).permit(:name, :email, :role)
      end
    end
  end
end
