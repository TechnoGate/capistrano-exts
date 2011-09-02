# encoding: utf-8

# Requirements
require 'capistrano'
require 'capistrano-technogate/receipts/base'
require 'capistrano-technogate/receipts/mysql'
require 'capistrano-technogate/receipts/servers/web_server'
require 'capistrano-technogate/receipts/servers/db_server'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do
      namespace :setup do
        desc "Prepare the server (database server, web server and folders)"
        task :default do
          # Empty task, server preparation goes into callbacks
        end

        task :verify_config do
          abort "You should configure the server_* section of deploy.rb" unless exists? :server_application_url
        end

        task :folders, :roles => :app do
          run <<-CMD
            mkdir -p #{deploy_to}
          CMD
        end

        task :finish do
          # Empty task for hooks
        end

      end
    end
  end

  # Callbacks
  before "deploy:server:setup", "deploy:server:setup:verify_config"
  after  "deploy:server:setup", "deploy:server:setup:finish"

  after "deploy:server:setup:verify_config", "deploy:server:setup:folders"
  after "deploy:server:setup:folders", "deploy:server:db_server:setup"
  after "deploy:server:db_server:setup", "deploy:server:web_server:setup"

  after "deploy:server:setup:finish", "deploy:setup"
end