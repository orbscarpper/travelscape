Rails.application.routes.draw do
  root to: "pages#home"

  devise_for :users

 resources :trips do
  resource :itinerary, only: [:show, :create, :edit, :update]

  resources :chats, only: [:index, :create, :show] do
    resources :messages, only: [:create]
  end
end

  get "up" => "rails/health#show", as: :rails_health_check
end
