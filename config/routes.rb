Rails.application.routes.draw do
  # Auth — clean user-facing URLs
  get    "/login",                 to: "sessions#new",       as: :login
  post   "/login",                 to: "sessions#create"
  delete "/logout",                to: "sessions#destroy",   as: :logout

  get    "/signup",                to: "registrations#new",  as: :signup
  post   "/signup",                to: "registrations#create"

  get    "/forgot-password",       to: "passwords#new",      as: :forgot_password
  post   "/forgot-password",       to: "passwords#create"
  get    "/reset-password/:token", to: "passwords#edit",     as: :reset_password
  patch  "/reset-password/:token", to: "passwords#update"
  put    "/reset-password/:token", to: "passwords#update"

  resource :account, only: [ :show, :update ] do
    delete :avatar, on: :member, action: :destroy_avatar
  end

  get "dashboard", to: "dashboard#index", as: :dashboard

  get "up" => "rails/health#show", as: :rails_health_check

  get "/explore", to: "explore#index", as: :explore

  resources :decks do
    member do
      get  :study
      get  :flashcard
      get  :match
      post :fork
    end
    resources :flashcards, shallow: true
  end

  resources :card_reviews, only: [ :create ]

  root "home#index"
end
