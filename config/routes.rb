Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/job_status"

  devise_for :users
  get "home/index"
  resources :reports, except: [ :index, :edit ] do
    get "result", to: "reports#result", on: :member
    get "retry", to: "reports#retry", on: :member
    get "clone", to: "reports#clone", on: :member
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :v2 do
    get "landing/index"
  end

  # Defines the root path route ("/")
  root "v2/landing#index"
end
