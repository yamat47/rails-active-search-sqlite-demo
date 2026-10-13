Rails.application.routes.draw do
  root "searches#show"
  resources :works, only: :show

  get "up" => "rails/health#show", as: :rails_health_check
end
