Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check

  resources :decks do
    member { get :study }
    resources :flashcards, shallow: true
  end

  resources :card_reviews, only: [:create]

  root "decks#index"
end
