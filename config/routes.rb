require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  resource :session
  # Sidekiq Web UI (password protected in production via SIDEKIQ_WEB_PASSWORD)
  if Rails.env.production?
    Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      ActiveSupport::SecurityUtils.secure_compare(user, "admin") &
        ActiveSupport::SecurityUtils.secure_compare(password, Rails.application.credentials.dig(:sidekiq, :web_password).to_s)
    end
  end
  mount Sidekiq::Web => "/sidekiq"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :articles, only: [ :index, :show ] do
    post :reanalyze, on: :member
  end
  resources :concepts, only: [ :index, :show ]
  resources :categories, only: [ :index, :show ]
  root "articles#index"
end
