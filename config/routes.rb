Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/job_status"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  %w[your_website your_brand order_confirmation pay receive_report].each do |action|
    get "analysis/#{action}", to: "analysis##{action}", as: :"#{action}"
    post "analysis/#{action}", to: "analysis#process_#{action}", as: :"process_#{action}"
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "landing/index"
  # Defines the root path route ("/")
  root "analysis#your_website"
end
