Rails.application.routes.draw do
  # Mount letter_opener_web for viewing emails in development
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  
  get '/login', to:'sessions#new'
  post '/login', to:'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get '/signup', to:'users#new'
  get '/help', to:'static_pages#help'
  get '/about', to:'static_pages#about'
  get '/contact', to:'static_pages#contact'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "static_pages#home"
  
  # Admin namespace
  namespace :admin do
    resources :users, only: [:index, :edit, :update, :destroy]
  end
  
  resources :users do
    collection do
      get :autocomplete
      get :search
    end
    member do
      get :following, :followers
    end
  end
  resources :account_activations, only: [:edit]
  resources :password_resets, only: [:new, :create, :edit, :update]
  
  resources :microposts, only: [:create, :destroy, :show, :update] do
    collection do
      get :search
      get :autocomplete
    end
    resources :likes, only: [:create, :destroy, :index]
    resources :comments, only: [:index, :create, :destroy]
  end
  
  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end
  
  resources :relationships, only: [:create, :destroy]
end
