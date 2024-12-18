# Given a URL
# Get SEO metatags
# Get the website details, try to find the homepage and an about section
class AboutYouJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
  end
end
