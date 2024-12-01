class AdminController < ApplicationController
  # Either the password is properly configured, or you won't be able to admin the app
  http_basic_authenticate_with name: "admin", password: Rails.application.credentials.admin_password.to_s
end
