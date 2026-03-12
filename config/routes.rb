
Rails.application.routes.draw do
  devise_for :users

  root to: "pages#home"

  resource :profile, only: [:show, :edit, :update]

  resources :offers, only: [:index, :show, :create, :destroy] do
    collection do
      post :scrape
      post :import
    end

    resources :chats, only: [:create]
    resources :cover_letters, only: [:create]


    member do
      post :apply
    end
  end

  resources :cover_letters, only: [:update]

	
  resources :chats, only: [:index, :show, :destroy] do
    resources :messages, only: [:create]
  end
end