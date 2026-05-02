# app/domains/fleet/services/route_generator.rb
module Fleet
  module Services
    class RouteGenerator
      def self.call(tenant:)
        new(tenant).call
      end

      def initialize(tenant)
        @tenant = tenant
      end

      def call
        # 1. Busca Lixeiras que precisam de coleta
        bins = @tenant.waste_bins.where("level >= ?", 50).includes(:bin_address)

        # 2. Busca Camiões disponíveis (e emparelha com motoristas disponíveis)
        trucks = @tenant.trucks.where(status: :available)
        drivers = @tenant.users.where(role: "driver") # Simplificação: pega motoristas da prefeitura

        return { error: "Lixeiras insuficientes" } if bins.empty?
        return { error: "Sem camiões disponíveis" } if trucks.empty?
        return { error: "Sem motoristas disponíveis" } if drivers.empty?

        # 3. Passa para o Gemini atuar como Gestor de Frota
        routes_allocation = optimize_multi_fleet_with_ai(bins, trucks)

        # 4. Criação atómica das múltiplas rotas no banco de dados
        created_routes = []

        ActiveRecord::Base.transaction do
          routes_allocation.each_with_index do |(truck_id, bin_ids), index|
            truck = trucks.find { |t| t.id == truck_id.to_i }
            driver = drivers[index % drivers.size] # Distribui motoristas pelos camiões

            next unless truck && bin_ids.any?

            # Cria a Rota Travada para este Camião
            route = @tenant.routes.create!(
              name: "Rota Automação - #{truck.plate} - #{Time.current.strftime('%d/%m')}",
              date: Date.current,
              truck: truck,
              driver: driver,
              status: :planned,
              locked: true
            )

            # Adiciona os pontos (lixeiras) na ordem definida pelo Gemini
            bin_ids.each_with_index do |bin_id, pos|
              bin = bins.find { |b| b.id == bin_id.to_i }
              route.route_points.create!(waste_bin: bin, position: pos + 1) if bin
            end

            created_routes << route
          end
        end

        { success: true, routes: created_routes }
      end

      private

      def optimize_multi_fleet_with_ai(bins, trucks)
        prompt = construct_vrp_prompt(bins, trucks)

        response = Ai::GeminiClient.new.generate(prompt)

        # Esperamos um hash do tipo: { "1": [5, 12], "2": [3, 8] }
        response.is_a?(Hash) ? response : fallback_allocation(bins, trucks)
      end

      def construct_vrp_prompt(bins, trucks)
        bins_data = bins.map { |b| { id: b.id, lat: b.bin_address.latitude, lng: b.bin_address.longitude, level: b.level } }
        trucks_data = trucks.map { |t| { id: t.id, lat: t.current_lat, lng: t.current_lng, capacity: t.capacity } }

        <<~PROMPT
          Você é o algoritmo de otimização de rotas logísticas (VRP) da EcoTrack.
          Seu objetivo é dividir uma lista de lixeiras entre os caminhões disponíveis para minimizar o tempo e a distância total percorrida.

          CAMINHÕES DISPONÍVEIS: #{trucks_data.to_json}
          LIXEIRAS PARA COLETAR: #{bins_data.to_json}

          REGRAS OBRIGATÓRIAS:
          1. Divida espacialmente as lixeiras: Lixeiras próximas umas das outras devem ser alocadas ao mesmo caminhão.
          2. Comece a rota considerando o ponto de partida (lat, lng) de cada caminhão.
          3. Retorne EXCLUSIVAMENTE um objeto JSON válido, onde a chave é o ID do caminhão (em string) e o valor é um array com os IDs das lixeiras na ordem ideal de visita.

          EXEMPLO DE RESPOSTA ESPERADA:
          {
            "1": [42, 15, 8],
            "2": [7, 91]
          }
        PROMPT
      end

      def fallback_allocation(bins, trucks)
        # Fallback caso a IA falhe: divide as lixeiras igualmente pelos camiões sem otimização geográfica
        allocation = {}
        bins_per_truck = bins.each_slice((bins.size / trucks.size.to_f).ceil).to_a

        trucks.each_with_index do |truck, index|
          allocation[truck.id.to_s] = bins_per_truck[index]&.map(&:id) || []
        end
        allocation
      end
    end
  end
end
