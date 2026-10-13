Rails.application.routes.draw do
  root "searches#show"

  get "up" => "rails/health#show", as: :rails_health_check
end
