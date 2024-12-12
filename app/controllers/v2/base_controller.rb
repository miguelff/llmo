class V2::BaseController < ApplicationController
  skip_before_action :authenticate_user!
  layout "v2/application"
end
