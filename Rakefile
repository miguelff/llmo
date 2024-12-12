# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"
require "tailwindcss/ruby"

module TailwindOverrides
  module Commands
    class << self
      def compile_command(debug: false, **kwargs)
        command = [
          Tailwindcss::Ruby.executable(**kwargs),
          "-i", Rails.root.join("app/assets/stylesheets/application.tailwind.v2.css").to_s,
          "-o", Rails.root.join("app/assets/builds/tailwind.v2.css").to_s,
          "-c", Rails.root.join("config/tailwind.config.v2.js").to_s
        ]

        command << "--minify" unless debug || rails_css_compressor?

        postcss_path = Rails.root.join("config/postcss.config.js")
        command += [ "--postcss", postcss_path.to_s ] if File.exist?(postcss_path)

        command
      end

      def watch_command(always: false, poll: false, **kwargs)
        compile_command(**kwargs).tap do |command|
          command << "-w"
          command << "always" if always
          command << "-p" if poll
        end
      end

      def rails_css_compressor?
        defined?(Rails) && Rails&.application&.config&.assets&.css_compressor.present?
      end
    end
  end
end

Rails.application.load_tasks



namespace :v2 do
  namespace :tailwindcss do
    desc "Build your Tailwind CSS"
    task build: :environment do |_, args|
        puts "**v2**"
        debug = args.extras.include?("debug")
        command = TailwindOverrides::Commands.compile_command(debug: debug)
        puts command.inspect if args.extras.include?("verbose")
        system(*command, exception: true)
    end

    desc "Watch and build your Tailwind CSS on file changes"
    task watch: :environment do |_, args|
        puts "**v2**"
        debug = args.extras.include?("debug")
        poll = args.extras.include?("poll")
        always = args.extras.include?("always")
        command = TailwindOverrides::Commands.watch_command(always: always, debug: debug, poll: poll)
        puts command.inspect if args.extras.include?("verbose")
        system(*command)
    rescue Interrupt
      puts "Received interrupt, exiting tailwindcss:watch" if args.extras.include?("verbose")
    end
  end
end

Rake::Task["tailwindcss:build"].enhance([ "v2:tailwindcss:build" ])
