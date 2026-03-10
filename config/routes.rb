
Rails.application.routes.draw do
  devise_for :users

  root to: "pages#home"

  get :my_profile, to: "users#my_profile"

  resources :offers, only: [:index, :show] do
    resources :chats, only: [:create]

    member do
      post :apply
      post :generate_cover_letter
    end
  end
	
  resources :chats, only: [:index, :show] do
    resources :messages, only: [:create]
  end
end