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
  namespace :server do
    desc "Prepare the server (database server, web server and folders)"
    task :prepare do
      # Empty task, server preparation goes into callbacks
    end

    namespace :prepare do
      task :verify_config do
        abort "You should configure the server_* section of deploy.rb" unless exists? :server_application_url
      end
      task :folders do
        run <<-CMD
          mkdir -p #{deploy_to}
        CMD
      end

      task :finish do
        # Empty task for hooks
      end
    end
  end

  # Callbacks
  before "server:prepare", "server:prepare:verify_config"
  after  "server:prepare", "server:prepare:finish"

  after "server:prepare:verify_config", "server:prepare:folders"
  after "server:prepare:folders", "server:db_server:prepare"
  after "server:db_server:prepare", "server:web_server:prepare"

  after "server:prepare:finish", "deploy:setup"
end