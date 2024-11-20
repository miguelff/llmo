source "https://rubygems.org"

# Core Rails and server gems
gem "rails", "~> 8.0.0"
gem "puma", ">= 5.0"
gem "bootsnap", require: false

# Database and caching
gem "sqlite3", ">= 2.1"
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "redis", "~> 5.3"

# Asset pipeline and frontend
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

# Deployment and performance
gem "kamal", require: false
gem "thruster", require: false

# Authentication and security
gem "devise", "~> 4.9"
gem "sentry-ruby"
gem "sentry-rails"

# Data handling and validation
gem "countries"
gem "addressable"
gem "hashie", "~> 5.0"
gem "dry-schema", "~> 1.13"

# AI/ML Integration
gem "ruby-openai", "~> 7.3"

# Cross-platform compatibility
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Optional features
# gem "bcrypt", "~> 3.1.7"
# gem "image_processing", "~> 1.2"

group :development, :test do
  # Debugging and profiling
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bullet"
  gem "rack-mini-profiler"
  gem "memory_profiler"
  gem "stackprof"

  # Code quality and security
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  # Development tools
  gem "letter_opener", "~> 1.10"
  gem "pry"
  gem "pry-rails"
  gem "pry-byebug"
end

group :development do
  # Development interface
  gem "web-console"
  gem "dockerfile-rails", ">= 1.6"
end

group :test do
  # Testing frameworks and tools
  gem "capybara"
  gem "selenium-webdriver"
  gem "rspec-rails", "~> 7.0.0"
  gem "webmock", "~> 3.24"
end

gem "vcr", "~> 6.3", group: :test
