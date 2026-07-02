Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      get "school/current", to: "schools#current"

      namespace :public do
        get "school", to: "schools#show"
        get "notices", to: "notices#index"
      end

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
      patch "auth/me", to: "auth/me#update"

      resources :notices, only: :index

      resources :study_materials, only: :index

      namespace :admin do
        resources :schools, only: :create
        resources :notices
        post "ai/notices", to: "ai_notices#create"
        resources :study_materials, only: %i[index create destroy]
        resources :students, only: %i[index create] do
          collection do
            post :import
          end
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
