require 'capistrano'
require 'capistrano-exts/receipts/deploy'
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
      run <<-CMD
        #{try_sudo} mkdir -p #{shared_path}/logs &&
        #{try_sudo} mkdir -p #{shared_path}/config &&
        #{try_sudo} mkdir -p #{shared_path}/contents &&
        #{try_sudo} mkdir -p #{shared_path}/contents/image &&
        #{try_sudo} mkdir -p #{shared_path}/contents/video &&
        #{try_sudo} mkdir -p #{shared_path}/contents/audio &&
        #{try_sudo} mkdir -p #{shared_path}/contents/pdf
      CMD
    end

    desc "[internal] Setup contao's localconfig"
    task :setup_localconfig, :roles => :app, :except => { :no_release => true } do
      on_rollback { run "rm -f #{shared_path}/config/localconfig.php" }

      localconfig = File.read("public/system/config/localconfig.php.sample")
      mysql_credentials = fetch :mysql_credentials
      mysql_db_name = fetch :mysql_db_name

      # localconfig
      if mysql_credentials.blank?
        puts "WARNING: The mysql credential file can't be found, localconfig has just been copied from the sample file"
      end

      # Add MySQL credentials
      unless localconfig.blank? or mysql_credentials.blank?
        localconfig.gsub!(/#DB_USER#/, mysql_credentials[:user])
        localconfig.gsub!(/#DB_PASS#/, mysql_credentials[:pass])
        localconfig.gsub!(/#DB_NAME#/, mysql_db_name)
      end

      put localconfig, "#{shared_path}/config/localconfig.php"
    end

    desc "[internal] Setup .htaccess"
    task :setup_htaccess do
      unless remote_file_exists?("#{fetch :shared_path}/config/htaccess.txt")
        begin
          run <<-CMD
            #{try_sudo} cp #{fetch :latest_release}/public/.htaccess.default #{fetch :shared_path}/config/htaccess.txt
          CMD
        rescue
          run <<-CMD
            #{try_sudo} touch #{fetch :shared_path}/config/htaccess.txt
          CMD
        end
      end
    end

    desc "[internal] Fix contao's symlinks to the shared path"
    task :fix_links, :roles => :app, :except => { :no_release => true } do
      contents_path = fetch :contents_path, "#{fetch :public_path}/tl_files/contents"

      # Remove files
      run <<-CMD
        #{try_sudo} rm -f #{contents_path} &&
        #{try_sudo} rm -rf #{fetch :latest_release}/public/system/logs &&
        #{try_sudo} rm -f #{fetch :latest_release}/public/system/config/localconfig.php &&
        #{try_sudo} rm -f #{fetch :latest_release}/public/.htaccess
      CMD

      run <<-CMD
        mkdir -p #{File.dirname(contents_path)}
      CMD

      # Create symlinks
      run <<-CMD
        #{try_sudo} ln -nsf #{fetch :shared_path}/contents #{contents_path} &&
        #{try_sudo} ln -nsf #{fetch :shared_path}/config/htaccess.txt #{fetch :latest_release}/public/.htaccess &&
        #{try_sudo} ln -nsf #{fetch :shared_path}/config/localconfig.php #{fetch :latest_release}/public/system/config/localconfig.php &&
        #{try_sudo} ln -nsf #{fetch :shared_path}/logs #{fetch :latest_release}/public/system/logs
      CMD
    end
  end

  # Dependencies
  after "deploy:setup", "contao:setup"
  after "contao:setup", "contao:setup_localconfig"
  after "deploy:finalize_update", "contao:fix_links"
  before "contao:fix_links", "contao:setup_htaccess"
  after "contao:fix_links", "deploy:cleanup"
  after "deploy:restart", "deploy:fix_permissions"

  # Mysql Credentials
  before "contao:setup_localconfig", "mysql:credentials"
  before "contao:setup_db", "mysql:credentials"
end