# app/domains/identity/serializers/role_attributes_resolver.rb
module Identity
  module Serializers
    module RoleAttributesResolver
      class << self
        def resolve(user)
          # Usa o método mapeado ou o método default se não encontrar o papel
          STRATEGIES.fetch(user.role, method(:default_attributes)).call(user)
        end

        private

        # 1. Método isolado para o Motorista
        def driver_attributes(user)
          {
            cnh_number: user.cnh_number,
            cnh_category: user.cnh_category,
            cnh_expiration_date: user.cnh_expiration_date&.iso8601
          }
        end

        # 2. Quando criar o Coletor, é só criar o método
        # def collector_attributes(user)
        #   { registration_id: user.registration_id }
        # end

        # 3. Fallback para papéis sem atributos extra (admin, suporte)
        def default_attributes(_user)
          {}
        end
      end

      # O Mapa fica super limpo lá no final do arquivo!
      STRATEGIES = {
        "driver" => method(:driver_attributes)
        # "collector" => method(:collector_attributes)
      }.freeze
    end
  end
end
