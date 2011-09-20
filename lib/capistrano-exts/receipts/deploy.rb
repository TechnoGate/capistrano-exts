require 'capistrano'
require 'capistrano/errors'
require 'capistrano-exts/receipts/functions'
require 'capistrano-exts/receipts/files'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    desc "Check if the remote is ready, should we run cap deploy:setup?"
    task :check_if_remote_ready, :roles => :web do
      unless remote_file_exists?("#{shared_path}")
        puts "ERROR: The project is not ready for deployment."
        puts "please run `cap deploy:setup"
        exit
      end
    end

    desc "Fix permissions"
    task :fix_permissions, :roles => :app do
      if exists?(:app_owner) or exists?(:app_group)
        run <<-CMD
          #{try_sudo} chown -R \
            #{fetch :app_owner, 'www-data'}:#{fetch :app_group, 'www-data'} \
            #{fetch :deploy_to}/releases \
            #{fetch :deploy_to}/shared
        CMD
      end

      run "chmod -R g+w #{fetch :latest_release}" if fetch(:group_writable, true)
    end

    desc "[internal] create the required folders."
    task :folders, :roles => :app do
      backup_path = fetch :backup_path, "#{fetch :deploy_to}/backups"

      run <<-CMD
        mkdir -p #{fetch :deploy_to} &&
        mkdir -p #{backup_path} &&
        mkdir -p #{fetch :shared_path}/items
      CMD

      if exists? :logs_path
        run <<-CMD
          mkdir -p #{fetch :logs_path}
        CMD
      end
    end

    desc "[internal] Symlink public folder"
    task :symlink_public_folders, :roles => :web, :except => { :no_release => true } do
      deploy_to = fetch :deploy_to

      ['htdocs', 'httpdocs', 'www'].each do |folder|
        if remote_file_exists?("#{deploy_to}/#{folder}")
          begin
            # Make sure the old folder exists
            run <<-CMD
              mkdir -p #{deploy_to}/old
            CMD

            run <<-CMD
              #{try_sudo} mv #{deploy_to}/#{folder} #{deploy_to}/old/#{folder} &&
              #{try_sudo} ln -nsf #{fetch :public_path} #{deploy_to}/#{folder}
            CMD
          rescue Capistrano::CommandError
            puts "WARNING: I couldn't replace the old htdocs please do so manually"
          end
        end
      end

      puts "The public folders has been moved to the old folder"
    end
  end

  # Dependencies
  before "deploy", "deploy:check_if_remote_ready"
  after "deploy:restart", "deploy:fix_permissions"
  after "deploy:setup", "deploy:folders"
  after "deploy:setup", "deploy:symlink_public_folders"
end