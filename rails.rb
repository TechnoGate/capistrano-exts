require 'capistrano'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do

  namespace :rails do
    desc "Install configuration files"
    task :install_configuration_files, :roles => :app do
      unless blank?(configuration_files)
        configuration_files.each { |configuration_file| link_config_file(configuration_file) }
      end
    end

    desc "Fix permissions"
    task :fix_permissions, :roles => :app do
      unless blank?(app_owner) or blank?(app_group)
        run "#{try_sudo} chown -R #{app_owner}:#{app_group} #{deploy_to}"
      end
    end
  end

  namespace :deploy do
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "#{try_sudo} touch #{File.join(current_path, 'tmp', 'restart.txt')}"
    end
  end

  after "deploy:finalize_update", "rails:install_configuration_files"
  after "deploy:restart", "rails:fix_permissions"
end