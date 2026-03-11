
Rails.application.routes.draw do
  devise_for :users

  root to: "pages#home"

  get :my_profile, to: "users#my_profile"

  resources :offers, only: [:index, :show, :create] do
    collection do
      post :scrape
    end

    resources :chats, only: [:create]
    resources :cover_letters, only: [:create]


    member do
      post :apply
    end
  end

  resources :cover_letters, only: [:update]

	
  resources :chats, only: [:index, :show] do
    resources :messages, only: [:create]
  end
end