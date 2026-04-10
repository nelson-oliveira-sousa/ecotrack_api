# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "/login", to: "authentication#login"
      delete "/logout", to: "authentication#logout"

      # Suas próximas rotas virão aqui:
      # get '/dashboard', to: 'dashboards#show'
    end
  end
end
