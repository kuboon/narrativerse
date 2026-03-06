Rails.application.routes.draw do
  resource :chat, only: [ :show, :create ] do
    resources :messages, only: [ :create ]
  end
  resources :models, only: [ :index, :show ] do
    collection do
      post :refresh
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"

  resources :elements, except: :destroy
  resources :plots, except: :destroy, shallow: true do
    resources :plot_elements, except: [ :index, :show ] do
      patch :refresh_revision, on: :member
    end
    resources :plot_scenes, only: [ :create ] do
      post :fork, on: :member
    end
  end

  # Update a scene in the context of a plot/link (allows direct update when plot owner)
  patch "plot_scenes/:id", to: "plot_scenes#update", as: :plot_scene

  get "reader/:plot_id", to: "reader#show", as: :reader
  get "reader/:plot_id(/:scene_id)", to: "reader#show", as: :reader_scene

  resource :session, only: [ :new, :create, :destroy ]
  resource :mypage, only: [ :show ], controller: :users
  resources :users, only: [ :new, :create ]

  # post "ai_assists/element_summary", to: "ai_assists#element_summary"
  # post "ai_assists/element_text", to: "ai_assists#element_text"
  # post "ai_assists/plot_summary", to: "ai_assists#plot_summary"
  # post "ai_assists/scene_text", to: "ai_assists#scene_text"
end
