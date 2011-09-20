require 'capistrano'
require 'capistrano/errors'
require 'capistrano-exts/receipts/functions'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :files do
    desc "[internal] Shared items"
    task :shared_items, :roles => :app, :except => { :no_release => true } do
      if exists?(:shared_items)
        link_files "#{fetch :shared_path}/items", fetch(:shared_items)
      end
    end

    desc "[internal] Configuration files"
    task :config_files, :roles => :app, :except => { :no_release => true } do
      if exists?(:configuration_files)
        link_files "#{fetch :shared_path}/config", fetch(:configuration_files)
      end
    end
  end

  # Dependencies
  after "deploy:finalize_update", "files:shared_items"
  after "deploy:finalize_update", "files:config_files"
end