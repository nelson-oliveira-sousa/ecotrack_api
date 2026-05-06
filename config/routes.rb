# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # ---------------------------------------------------------
      # 🔓 VIA VERDE (Sem JWT) - Hardware
      # ---------------------------------------------------------
      post "bins/:id/sensor", to: "bins#sensor"

      # ---------------------------------------------------------
      # 🔐 AUTENTICAÇÃO, TENANTS E IDENTIDADE
      # ---------------------------------------------------------
      post "login", to: "authentication#login"
      delete "logout", to: "authentication#logout"
      get "me", to: "authentication#me"

      # [NOVO] Adicionado para o fluxo de Primeiro Acesso (MVP)
      patch "update_password", to: "passwords#update_password"
      resources :users, only: [ :index, :create, :show, :update, :destroy ]

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
          # O método def stream ficará no AlertsController
          get :stream
        end
        member do
          patch :resolve
        end
      end

      # ---------------------------------------------------------
      # 🗑️ LIXEIRAS & CAMINHÕES
      # ---------------------------------------------------------
      resources :bins, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          patch :collect, to: "bins#collect"
          patch :toggle_status, to: "bins#toggle_status" # [NOVO]
        end
      end

      resources :trucks, only: %i[index show create update destroy] do
        member do
          patch :location, to: "trucks#update_location"
        end
      end

      # ---------------------------------------------------------
      # 🗺️ ROTAS (IA - Gemini) e OPERAÇÃO
      # ---------------------------------------------------------
      resources :routes, only: [] do
        collection do
          get :today
          # [AJUSTADO] Movido para cá para combinar com o RoutesController que fizemos
          post :generate
        end
        member do
          post :start
          post "stops/:bin_id/collect", to: "routes#collect_stop"
        end
      end

      # Mantido para futuras implementações focadas em Turnos
      resources :shifts, only: [ :index ]
    end
  end
end
