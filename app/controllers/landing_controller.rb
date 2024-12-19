class LandingController < ApplicationController
  def index
    @your_website = Analysis::YourWebsite.empty
  end
end
