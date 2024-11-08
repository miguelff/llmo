host = ENV["WEB_HOST"] || begin
  if Rails.env.development?
    "localhost:3000"
  else
    raise("WEB_HOST is not set for environment #{Rails.env}")
  end
end

Rails.application.routes.draw do
  default_url_options host: host

  resources :reports, except: [ :index, :edit ] do
    get "result", to: "reports#result", on: :member
  end

  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "reports#new"
end
