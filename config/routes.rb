Rails.application.routes.draw do
  # Health check (no authentication).
  get "up" => "rails/health#show", as: :rails_health_check

  # Public storefront root.
  root "home#index"

  # Signup
  get  "/signup",  to: "users#new",         as: :signup
  post "/signup",  to: "users#create"

  # Login / logout
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # Email confirmation
  get "/email/confirm", to: "email_confirmations#show", as: :email_confirmation

  # Password reset
  get   "/password",          to: "passwords#new",     as: :new_password
  post  "/password",          to: "passwords#create",  as: :passwords
  get   "/password/edit",     to: "passwords#edit",    as: :edit_password
  patch "/password",          to: "passwords#update",  as: :update_password
end
