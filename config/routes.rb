Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"
  resource :session, only: [ :new, :create, :destroy ]
  resource :mypage, only: [ :show ], controller: :users
  resources :users, only: [ :new, :create ]

  resources :elements, except: :destroy

  resources :plots, except: [ :destroy, :create ], shallow: true do
    resources :plot_elements, except: [ :index, :show ], as: :elements do
      patch :refresh_revision, on: :member
    end
    resources :plot_scene_links, only: [ :create, :update ] do
      post :fork, on: :member
    end
  end
  resource :chat, only: %i[ show ]
  resources :messages, only: [ :create ]
  post "mcp(/:plot_id)", to: "mcp#create", as: :mcp

  get "reader/:plot_id(/:scene_id)", to: "reader#show", as: :reader

  if Rails.env.development? || Rails.env.test?
    namespace :dev do
      resources :ui_feedbacks, only: [ :create ]
    end
  end
end
