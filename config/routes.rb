# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # ---------------------------------------------------------
      # 🔓 VIA VERDE (Sem JWT) - Hardware
      # ---------------------------------------------------------
      # Endpoint livre para o ESP32 do Mauricio enviar os dados
      post "bins/:id/sensor", to: "bins#sensor"

      # ---------------------------------------------------------
      # 🔐 AUTENTICAÇÃO E TENANTS
      # ---------------------------------------------------------
      post "login", to: "authentication#login"
      delete "logout", to: "authentication#logout"
      get "me", to: "authentication#me"

      resources :tenants, only: [ :create ]
      get "tenants/:slug/validate", to: "tenants#validate"

      # ---------------------------------------------------------
      # 📊 DASHBOARD (Admin)
      # ---------------------------------------------------------
      get "dashboard/summary", to: "analytics#summary"

      # ---------------------------------------------------------
      # 🚨 ALERTAS (Geral & SSE)
      # ---------------------------------------------------------
      resources :alerts, only: [ :index ] do
        collection do
          get :stream # O nosso túnel em tempo real (PostgreSQL LISTEN)
        end
        member do
          patch :resolve
        end
      end

      # ---------------------------------------------------------
      # 🗑️ LIXEIRAS & CAMINHÕES
      # ---------------------------------------------------------
      resources :bins, only: [ :index, :show ] do
        member do
          patch :collect
        end
      end

      resources :trucks do
        member do
          # O GPS Mobile envia para cá a cada 30s (Lembre-se de dar skip_before_action no controller)
          patch :location, to: "trucks#update_location"
        end
      end

      # ---------------------------------------------------------
      # 🗺️ ROTAS E TURNOS (IA - Gemini)
      # ---------------------------------------------------------
      resources :shifts, only: [ :index ] do
        member do
          post :generate # Cérebro: Admin pede para dividir as rotas do turno
        end
      end

      resources :routes, only: [] do
        collection do
          get :today
        end
        member do
          post :start
          post "stops/:bin_id/collect", to: "routes#collect_stop"
        end
      end

      # ---------------------------------------------------------
      # 📱 APP DO MOTORISTA
      # ---------------------------------------------------------
      resource :my_route, only: [ :show ] do
        post :generate # Cérebro: Motorista pede a sua própria rota (síncrono)
      end
    end
  end
end
