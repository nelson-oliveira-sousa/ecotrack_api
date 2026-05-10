# app/domains/identity/forms/role_attributes_resolver.rb
module Identity
  module Forms
    module RoleAttributesResolver
      # Mapa seguro de estratégias
      STRATEGIES = {
        "driver" => ->(f) { { cnh_number: f.cnh_number, cnh_expiration_date: f.cnh_expiration_date, cnh_category: f.cnh_category } }
        # "collector" => ->(f) { { registration_id: f.registration_id } }
      }.freeze

      def self.resolve(form)
        # Retorna os campos específicos ou um hash vazio se não houver mapeamento
        STRATEGIES.fetch(form.role, ->(_) { {} }).call(form)
      end
    end
  end
end
