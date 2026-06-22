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

  resource :account, only: [ :show, :update, :destroy ] do
    delete :avatar, on: :member, action: :destroy_avatar
  end

  get "dashboard", to: "dashboard#index", as: :dashboard

  get "up" => "rails/health#show", as: :rails_health_check

  get "/explore", to: "explore#index", as: :explore
  resources :decks, except: [:new] do
    member do
      get   :unlock, to: "deck_access#show"
      post  :unlock, to: "deck_access#create"
      get   :study, to: "study_sessions#show"
      get   :flashcard
      get   :match
      get   :learn, to: "learn_sessions#show"
      get   :test, to: "test_sessions#show"
      post  :copy, to: "deck_copy#create"
      patch :update_visibility
    end
    resources :flashcards, shallow: true, only: [:create, :update, :destroy] do
      member do
        patch :restore
      end
    end
    resource :import, only: [], controller: :imports do
      post :text, on: :collection
      post :csv,  on: :collection
    end
  end

  resources :folders do
    member do
      get   :rename_modal
      get   :delete_modal
      get   :add_decks_modal
      patch :update_deck_assignments
    end
    resource :deck, only: [:destroy], controller: "folder_decks"
  end
  resources :folder_deck_assignments, only: [:create, :new]

  resources :users, only: [ :show ], param: :username do
    resource :follow, only: [ :create, :destroy ], controller: "follows"
  end

  resources :notifications, only: [ :index ] do
    collection do
      patch :mark_all_read
    end
    member do
      patch :mark_read
    end
  end

  resources :card_reviews, only: [ :create ]
  resources :study_sessions, only: [ :index ]
  resources :learn_answers, only: [ :create ]
  resources :test_answers, only: [ :create ]

  resources :card_progresses, only: [] do
    resource :starred_card, only: [ :create, :destroy ]
  end

  get "suggestions", to: "suggestions#index"

  root "home#index"
end
