Rails.application.routes.draw do
  root "searches#show"
  get "tokenizers" => "tokenizers#show", as: :tokenizers

  get "up" => "rails/health#show", as: :rails_health_check
end
