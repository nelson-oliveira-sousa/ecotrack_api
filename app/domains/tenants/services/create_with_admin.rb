# app/domains/tenants/services/create_with_admin.rb
module Tenants
  module Services
    class CreateWithAdmin
      def self.call(tenant_params:, admin_params:)
        new(tenant_params, admin_params).call
      end

      def initialize(tenant_params, admin_params)
        @tenant_params = tenant_params
        @admin_params = admin_params
      end

      def call
        # Transação garante que ou cria tudo perfeitamente, ou não cria nada.
        ActiveRecord::Base.transaction do
          # 1. Cria a Prefeitura
          # O code e slug serão gerados SOZINHOS pelos callbacks do model Tenant!
          @tenant = Tenant.create!(
            name: @tenant_params[:name],
            status: :active
          )

          # 2. Cria o Perfil Fiscal (se houver dados)
          if @tenant_params[:document].present? || @tenant_params[:contact_email].present?
            @tenant.create_profile!(
              document: @tenant_params[:document],
              contact_email: @tenant_params[:contact_email],
              contact_phone: @tenant_params[:contact_phone]
            )
          end

          # 3. Cria o primeiro Usuário (Admin) vinculado à prefeitura
          @admin = @tenant.users.create!(
            name: @admin_params[:name],
            email: @admin_params[:email],
            password: @admin_params[:password],
            role: "admin"
          )
        end

        # Sucesso: devolve os objetos para o controller renderizar
        { success: true, tenant: @tenant, admin: @admin }

      rescue ActiveRecord::RecordInvalid => e
        # Falha de Validação (ex: senha fraca, nome em branco): Devolve o erro limpo
        { success: false, error: e.record.errors.full_messages.join(", ") }
      rescue => e
        # Falha Inesperada
        { success: false, error: "Erro interno: #{e.message}" }
      end
    end
  end
end
