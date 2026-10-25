Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Public catalog. The landing replaces the provisional home page.
  root "catalog/landing#index"
  get "products", to: "catalog/products#index", as: :products
  get "products/:slug", to: "catalog/products#show", as: :product
  get "categories/:slug", to: "catalog/categories#show", as: :category
  get "sitemap", to: "catalog/sitemap#show", as: :sitemap, defaults: { format: :xml }
  get "robots", to: "catalog/robots#show", as: :robots, defaults: { format: :text }

  # Authentication (login/logout)
  get "login", to: "auth/sessions#new", as: :login
  post "login", to: "auth/sessions#create"
  delete "logout", to: "auth/sessions#destroy", as: :logout

  # Sign up
  get "signup", to: "auth/registrations#new", as: :signup
  post "signup", to: "auth/registrations#create"

  # Password reset. The token travels as a query parameter (not in the URL
  # path) so Rails' filtered_path keeps it out of the server logs.
  get "password/reset", to: "auth/passwords#new", as: :new_password
  post "password/reset", to: "auth/passwords#create"
  get "password/reset/edit", to: "auth/passwords#edit", as: :edit_password
  patch "password/reset", to: "auth/passwords#update", as: :update_password

  # Profile
  resource :profile, only: %i[show edit update], controller: "users/profiles"

  # Locale switching
  post "locale", to: "locales#update", as: :locale
end
