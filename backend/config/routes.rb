Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      get "school/current", to: "schools#current"

      devise_for :users,
                 path: "auth",
                 only: %i[sessions passwords],
                 controllers: {
                   sessions: "api/v1/auth/sessions",
                   passwords: "api/v1/auth/passwords"
                 },
                 path_names: {
                   sign_in: "login",
                   sign_out: "logout",
                   password: "password"
                 }

      get "auth/me", to: "auth/me#show"

      namespace :admin do
        resources :schools, only: :create
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
