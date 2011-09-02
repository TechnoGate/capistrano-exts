# encoding: utf-8

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do
      namespace :db_server do
        desc "Setup db server"
        task :setup, :roles => :db do
          # Empty task, server preparation goes into callbacks
        end
      end
    end
  end
end