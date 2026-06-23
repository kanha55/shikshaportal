Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      get "school/current", to: "schools#current"

      namespace :admin do
        resources :schools, only: :create
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
