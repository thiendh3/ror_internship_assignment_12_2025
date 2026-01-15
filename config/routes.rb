Rails.application.routes.draw do
  # Mount Action Cable
  mount ActionCable.server => '/cable'
  
  get "/login", to:"sessions#new"
  post "/login", to:"sessions#create"
  delete "/logout", to: "sessions#destroy"
  get "/signup", to:"users#new"
  get "/help", to:"static_pages#help"
  get "/about", to:"static_pages#about"
  get "/contact", to:"static_pages#contact"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "static_pages#home"
  resources :users do
    member do
      get :following, :followers
    end
  end
  resources :account_activations, only: [ :edit ]
  resources :password_resets, only: [ :new, :create, :edit, :update ]
  resources :microposts, only: [ :create, :destroy, :show, :update ] do
    member do
      post "like", to: "likes#create"
      get "likes", to: "likes#index"
      delete "like", to: "likes#destroy"
    end
  end
  resources :relationships, only: [ :create, :destroy ]
  get "/search", to: "search#index"
  get "/search/autocomplete", to: "search#autocomplete"
  
  resources :notifications, only: [:index] do
    collection do
      get :unread_count
      put :mark_all_as_read
    end
    member do
      put :mark_as_read
    end
  end
end
