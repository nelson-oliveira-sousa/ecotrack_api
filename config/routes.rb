# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Autenticação
      post "login", to: "authentication#login"
      delete "logout", to: "authentication#logout"
      get "me", to: "authentication#me"

      # Domínio de Tenants - Refatorado para GET com Path Param
      # Isso gera: GET /api/v1/tenants/guaicara-sp/validate
      get "tenants/:slug/validate", to: "tenants#validate"
    end
  end
end
