require 'capistrano'
require 'capistrano-exts/receipts/deploy'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

# TODO:
# => Replace the vars with a call to fetch
# => Add the vars to examples and the template so it is visible

Capistrano::Configuration.instance(:must_exist).load do

  namespace :rails do
    desc "Install configuration files"
    task :install_configuration_files, :roles => :app do
      if exists?(:configuration_files)
        fetch(:configuration_files).each { |configuration_file| link_config_file(configuration_file) }
      end
    end

    desc "Install rvm config file"
    task :install_rvmrc_file, :roles => :app do
      link_file(File.join(fetch(:shared_path), 'rvmrc'), File.join(fetch(:release_path), '.rvmrc'))
    end
  end

  namespace :deploy do
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "#{try_sudo} touch #{File.join(current_path, 'tmp', 'restart.txt')}"
    end
  end

  after "deploy:finalize_update", "rails:install_configuration_files"
  after "rails:install_configuration_files", "rails:install_rvmrc_file"
  after "deploy:restart", "deploy:fix_permissions"

  # Capistrano is broken
  # See: https://github.com/capistrano/capistrano/issues/81
  before "deploy:assets:precompile", "bundle:install"
end