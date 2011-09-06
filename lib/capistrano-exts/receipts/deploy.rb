require 'capistrano'
require 'capistrano/errors'
require 'capistrano-exts/receipts/functions'

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
      unless exists?(:app_owner) or exists?(:app_group)
        run <<-CMD
          #{try_sudo} chown -R \
            #{fetch :app_owner, 'www-data'}:#{fetch :app_group, 'www-data'} \
            #{fetch :deploy_to}/releases \
            #{fetch :deploy_to}/shared
        CMD
      end

      run "chmod -R g+w #{fetch :latest_release}" if fetch(:group_writable, true)
    end

    desc "[internal] Symlink htdocs"
    task :symlink_htdocs do
      deploy_to = fetch :deploy_to
      if remote_file_exists?("#{deploy_to}/htdocs")
        begin
          run <<-CMD
            #{try_sudo} mv #{deploy_to}/htdocs #{deploy_to}/old_htdocs &&
            #{try_sudo} ln -nsf #{fetch :public_path} #{deploy_to}/htdocs
          CMD
        rescue Capistrano::CommandError
          puts "WARNING: I couldn't replace the old htdocs please do so manually"
        end
      end

      puts "The htdocs folder has been moved to old_htdocs"
    end
  end

  # Dependencies
  before "deploy", "deploy:check_if_remote_ready"
  after "deploy:restart", "deploy:fix_permissions"
  after "deploy:setup", "deploy:symlink_htdocs"
end