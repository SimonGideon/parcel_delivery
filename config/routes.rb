Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/docs'
  mount Rswag::Api::Engine => '/docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"

      post "login", to: "sessions#create"

      resources :users, only: %i[create]
      resources :drivers, only: %i[create]
      resources :driver_locations, only: %i[create]
      resources :countries, only: %i[index]
      resources :counties, only: %i[index]

      get "customer/delivery_requests", to: "delivery_requests#customer_index"
      get "driver/delivery_requests", to: "delivery_requests#driver_index"

      resources :delivery_requests, only: %i[show create] do
        post :cancel, on: :member
        post :accept, on: :member
        post :reject, on: :member
        post :pick_up, on: :member
        post :deliver, on: :member

        resources :events, only: %i[index], controller: "delivery_events"
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
