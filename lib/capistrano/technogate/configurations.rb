require 'capistrano'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  unless ENV['DEPLOY'].nil? or ENV['DEPLOY'].empty?
    # Set the operation were doing
    set :deploying, ENV['DEPLOY'].to_sym

    if configurations[deploying].nil?
      puts "ERROR: #{ENV['DEPLOY']} has not been configured yet, please open up 'config/deploy.rb' and configure it"
      exit
    end

    # Parse configurations
    configurations[deploying].each { |config, value| set config, value }

    # Set the current path
    set :current_path, "#{File.join deploy_to, 'current'}"
  end
end