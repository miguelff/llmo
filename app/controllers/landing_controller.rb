class LandingController < ApplicationController
  def index
    @your_website = Analysis::YourWebsite::Form.new
  end
end
