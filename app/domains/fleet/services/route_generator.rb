# app/domains/fleet/services/route_generator.rb
module Fleet
  module Services
    class RouteGenerator
      def self.call(tenant:)
        new(tenant).call
      end

      def initialize(tenant)
        @tenant = tenant
        @channel = "alerts_tenant_#{@tenant.id}" # O exato canal que seu SSE escuta[cite: 1]
      end

      def call
        broadcast_update("processing", "Iniciando varredura de lixeiras críticas...")

        bins = @tenant.waste_bins
                      .where("level >= ? OR status IN (?)", 50, %w[critical warning])
                      .includes(:bin_address)
        trucks = @tenant.trucks.where(status: :available)
        drivers = @tenant.users.where(role: :driver) # Corrigido para símbolo (enum)[cite: 1]

        if bins.empty? || trucks.empty? || drivers.empty?
          broadcast_update("error", "Recursos insuficientes (lixeiras, caminhões ou motoristas).")
          return { error: "Recursos insuficientes" }
        end

        broadcast_update("processing", "Consultando inteligência artificial (Gemini) para otimização VRP...")

        # 2. Passa para o Gemini
        routes_allocation = optimize_multi_fleet_with_ai(bins, trucks)

        broadcast_update("processing", "IA finalizou. Salvando rotas no banco de dados...")
        created_routes = []

        # 3. Criação atómica das múltiplas rotas[cite: 1]
        ActiveRecord::Base.transaction do
          routes_allocation.each_with_index do |(truck_id, bin_ids), index|
            truck = trucks.find { |t| t.id == truck_id.to_i }
            driver = drivers[index % drivers.size]

            next unless truck && bin_ids.any?

            route = @tenant.routes.create!(
              name: "Rota Smart - #{truck.plate} - #{Time.current.strftime('%d/%m')}",
              date: Date.current,
              truck: truck,
              driver: driver,
              status: :planned,
              locked: true
            )

            bin_ids.each_with_index do |bin_id, pos|
              bin = bins.find { |b| b.id == bin_id.to_i }
              route.route_points.create!(waste_bin: bin, position: pos + 1) if bin
            end

            created_routes << route
          end
        end

        # 4. Serializa as rotas criadas para enviar pro Frontend
        serialized_routes = created_routes.as_json(
          include: {
            route_points: { include: { waste_bin: { only: [ :id, :label, :level, :status ] } } }
          }
        )

        # AVISA O FRONTEND QUE ACABOU E ENTREGA OS DADOS!
        broadcast_update("route_ready", "Rotas geradas e otimizadas com sucesso!", serialized_routes)

        { success: true, routes: created_routes }
      rescue => e
        broadcast_update("error", "Erro no gerador: #{e.message}")
        { success: false, error: e.message }
      end

      private

      def optimize_multi_fleet_with_ai(bins, trucks)
        prompt = construct_vrp_prompt(bins, trucks)
        response = Ai::GeminiClient.generate(prompt, purpose: :general_purpose)
        response.is_a?(Hash) ? response : fallback_allocation(bins, trucks)
      end

      def construct_vrp_prompt(bins, trucks)
        bins_data = bins.map do |b|
          {
            id: b.id,
            lat: b.bin_address&.latitude,
            lng: b.bin_address&.longitude,
            level: b.level
          }
        end
        trucks_data = trucks.map { |t| { id: t.id, lat: t.current_lat, lng: t.current_lng, capacity: t.capacity } }

        <<~PROMPT
          Você é o algoritmo de otimização de rotas logísticas (VRP) da EcoTrack.
          Seu objetivo é dividir uma lista de lixeiras entre os caminhões disponíveis para minimizar o tempo e a distância total percorrida.

          CAMINHÕES DISPONÍVEIS: #{trucks_data.to_json}
          LIXEIRAS PARA COLETAR: #{bins_data.to_json}

          REGRAS OBRIGATÓRIAS:
          1. Divida espacialmente as lixeiras: Lixeiras próximas umas das outras devem ser alocadas ao mesmo caminhão.
          2. Comece a rota considerando o ponto de partida (lat, lng) de cada caminhão.
          3. Retorne EXCLUSIVAMENTE um objeto JSON válido, onde a chave é o ID do caminhão (em string) e o valor é um array com os IDs das lixeiras na ordem ideal de visita. Não use blocos de código (markdown).
        PROMPT
      end

      def fallback_allocation(bins, trucks)
        allocation = {}
        bins_per_truck = bins.each_slice((bins.size / trucks.size.to_f).ceil).to_a
        trucks.each_with_index do |truck, index|
          allocation[truck.id.to_s] = bins_per_truck[index]&.map(&:id) || []
        end
        allocation
      end

      # O MENSAGEIRO: Dispara o NOTIFY pro PostgreSQL[cite: 1]
      def broadcast_update(event_type, message, data = nil)
        payload = {
          event: event_type,
          message: message,
          data: data
        }.compact.to_json

        # Executa o NOTIFY direto no PG. Quem estiver no LISTEN (o controller stream) recebe na hora.
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array([ "NOTIFY %s, '%s'", @channel, payload ])
        )
      end
    end
  end
end
