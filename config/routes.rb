# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Autenticação
      post "login", to: "authentication#login"
      delete "logout", to: "authentication#logout"
      get "me", to: "authentication#me"

      # Domínio de Tenants (Prefeituras)
      # ADICIONADO: Permite o POST /api/v1/tenants
      resources :tenants, only: [ :create ]

      # GET /api/v1/tenants/guaicara-sp/validate
      get "tenants/:slug/validate", to: "tenants#validate"

      # Dashboard
      get "dashboard/summary", to: "analytics#summary"

      # Lixeiras
      resources :bins, only: [ :index, :show ] do
        member do
          patch :collect # PATCH /api/v1/bins/:id/collect
        end
      end

      resources :trucks do
        member do
          patch :location, to: "trucks#update_location" # PATCH /api/v1/trucks/:id/location
        end
      end

      resources :routes, only: [] do
        collection do
          get :today # GET /api/v1/routes/today
        end

        member do
          post :start # POST /api/v1/routes/:id/start
          # A URL complexa de paragens: POST /api/v1/routes/:id/stops/:bin_id/collect
          post "stops/:bin_id/collect", to: "routes#collect_stop"
        end
      end
    end
  end
end
