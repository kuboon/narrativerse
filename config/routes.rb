Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"

  resources :elements, except: :destroy
  resources :plots, except: :destroy do
    get "plot_scene_links/:link_id", to: "reader#show", as: :plot_scene_link
    resources :plot_elements, except: [ :index, :show ] do
      patch :refresh_revision, on: :member
    end
    resources :plot_scene_links, only: [ :new, :create ] do
      post :fork, on: :member
    end
  end

  get "reader/:plot_id", to: "reader#show", as: :reader
  get "reader/:plot_id/:link_id", to: "reader#show", as: :reader_link

  resource :session, only: [ :new, :create, :destroy ]
  resources :users, only: [ :new, :create ]

  post "ai_assists/element_summary", to: "ai_assists#element_summary"
  post "ai_assists/element_text", to: "ai_assists#element_text"
  post "ai_assists/plot_summary", to: "ai_assists#plot_summary"
  post "ai_assists/scene_text", to: "ai_assists#scene_text"
end
