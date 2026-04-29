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
    end
  end
end
