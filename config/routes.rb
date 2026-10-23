Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # Temporary home until the public catalog/landing exists (see AGENTS.full.md).
  root "home#index"

  # Authentication (login/logout)
  get "login", to: "auth/sessions#new", as: :login
  post "login", to: "auth/sessions#create"
  delete "logout", to: "auth/sessions#destroy", as: :logout

  # Sign up
  get "signup", to: "auth/registrations#new", as: :signup
  post "signup", to: "auth/registrations#create"

  # Password reset
  get "password/reset", to: "auth/passwords#new", as: :new_password
  post "password/reset", to: "auth/passwords#create"
  get "password/reset/:token/edit", to: "auth/passwords#edit", as: :edit_password
  patch "password/reset/:token", to: "auth/passwords#update", as: :update_password

  # Profile
  resource :profile, only: %i[show edit update], controller: "users/profiles"

  # Locale switching
  post "locale", to: "locales#update", as: :locale
end
