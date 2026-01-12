require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  # Auth
  get "/login", to: "sessions#new", as: :login
  resource :session, only: [:create, :destroy]

  # Sidekiq Web UI (password protected in production)
  if Rails.env.production?
    Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      ActiveSupport::SecurityUtils.secure_compare(user, "admin") &
        ActiveSupport::SecurityUtils.secure_compare(password, Rails.application.credentials.dig(:sidekiq, :web_password).to_s)
    end
  end
  mount Sidekiq::Web => "/sidekiq"

  # Admin namespace (all Inertia)
  namespace :admin do
    root "dashboard#index"

    resources :articles do
      post :reanalyze, on: :member
    end
    resources :stories
    resources :concepts
    resources :categories
    resources :prompts do
      post :activate, on: :member
    end
    resources :users
    resources :article_analyses, only: [:index, :show, :destroy]
    resources :trend_snapshots, only: [:index]
    resources :article_concepts, only: [:index, :destroy]
    resources :article_subjects, only: [:index, :destroy]
    resources :article_categories, only: [:index, :destroy]
    resources :sessions, only: [:index, :destroy]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Redirect root to admin
  root to: redirect("/admin")
end
