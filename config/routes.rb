# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "bins/:id/sensor", to: "bins#sensor"

      post "login", to: "authentication#login"
      delete "logout", to: "authentication#logout"
      get "me", to: "authentication#me"

      patch "update_password", to: "passwords#update_password"
      resources :users, only: [ :index, :create, :show, :update, :destroy ]

      resources :tenants, only: [ :create ]
      get "tenants/:slug/validate", to: "tenants#validate"

      get "dashboard/summary", to: "analytics#summary"

      resources :alerts, only: [ :index ] do
        collection do
          get :stream
        end
        member do
          patch :resolve
        end
      end

      resources :bins, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          patch :collect, to: "bins#collect"
          patch :toggle_status, to: "bins#toggle_status"
        end
      end

      resources :trucks, only: %i[index show create update destroy] do
        member do
          patch :location, to: "trucks#update_location"
          patch :toggle_status, to: "trucks#toggle_status"
        end
      end

      resources :routes, only: [] do
        collection do
          get :today
          post :generate
        end
        member do
          post :start
          post "stops/:bin_id/collect", to: "routes#collect_stop"
        end
      end

      resources :shifts, only: [ :index ]
    end
  end
end
