class LandingController < ApplicationController
  def index
    @your_website = Analysis::Website.empty
  end
end
