Rails.application.routes.draw do
  resource  :session,      only: [ :new, :create, :destroy ]
  resources :passwords,    param: :token, only: [ :new, :create, :edit, :update ]
  resource  :registration, only: [ :new, :create ]
  resource  :account,      only: [ :show, :update ]

  get "dashboard", to: "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :decks do
    member { get :study }
    resources :flashcards, shallow: true
  end

  resources :card_reviews, only: [ :create ]

  root "dashboard#index"
end
