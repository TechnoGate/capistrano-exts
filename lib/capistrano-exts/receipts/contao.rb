require 'capistrano-exts/receipts/mysql'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  # Prevent capistrano from creating log, system and pids folders.
  set :shared_children, Array.new

  namespace :deploy do
    desc "Empty task, overriden by #{__FILE__}"
    task :finalize_update do
      # Empty task, we do not want to delete the system folder.
    end
  end

  namespace :contao do
    desc "[internal] Setup contao shared contents"
    task :setup, :roles => :app, :except => { :no_release => true } do
      shared_path = fetch :shared_path
      run <<-CMD
        #{try_sudo} mkdir -p #{shared_path}/logs &&
        #{try_sudo} mkdir -p #{shared_path}/config
      CMD

      # TODO: The deny access should follow denied_access config
      deny_htaccess = "order deny,allow\n"
      deny_htaccess << "deny from all"

      put deny_htaccess, "#{shared_path}/logs/.htaccess"
    end

    desc "[internal] Setup contao's localconfig"
    task :setup_localconfig, :roles => :app, :except => { :no_release => true } do
      localconfig_php_config_path = "#{fetch :shared_path}/config/public_system_config_localconfig.php"
      unless remote_file_exists?(localconfig_php_config_path)
        on_rollback { run "rm -f #{localconfig_php_config_path}" }

        localconfig = File.read("public/system/config/localconfig.php.sample")
        mysql_credentials = fetch :mysql_credentials
        mysql_db_name = fetch :mysql_db_name

        # localconfig
        if mysql_credentials.blank?
          logger.info "WARNING: The mysql credential file can't be found, localconfig has just been copied from the sample file"
        end

        # Add MySQL credentials
        unless localconfig.blank? or mysql_credentials.blank?
          localconfig.gsub!(/#DB_HOST#/, mysql_credentials[:host])
          localconfig.gsub!(/#DB_USER#/, mysql_credentials[:user])
          localconfig.gsub!(/#DB_PASS#/, mysql_credentials[:pass])
          localconfig.gsub!(/#DB_NAME#/, mysql_db_name)
        end

        put localconfig, localconfig_php_config_path
      else
        logger.info "WARNING: The file '#{localconfig_php_config_path}' already exists, not overwriting."
      end
    end

    desc "[internal] Fix contao's symlinks to the shared path"
    task :fix_links, :roles => :app, :except => { :no_release => true } do
      latest_release = fetch :latest_release
      shared_path = fetch :shared_path

      # Remove files
      run <<-CMD
        #{try_sudo} rm -rf #{latest_release}/public/system/logs
      CMD

      # Create symlinks
      run <<-CMD
        #{try_sudo} ln -nsf #{shared_path}/logs #{latest_release}/public/system/logs
      CMD
    end
  end

  # Dependencies
  after "deploy:setup", "contao:setup"
  after "contao:setup", "contao:setup_localconfig"
  after "deploy:finalize_update", "contao:fix_links"

  # Mysql Credentials
  before "contao:setup_localconfig", "mysql:credentials"
  before "contao:setup_db", "mysql:credentials"
end