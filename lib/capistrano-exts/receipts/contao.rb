require 'capistrano'
require 'capistrano-exts/receipts/deploy'
require 'capistrano-exts/receipts/mysql'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
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
        #{try_sudo} mkdir -p #{shared_path}/log &&
        #{try_sudo} mkdir -p #{shared_path}/contenu &&
        #{try_sudo} mkdir -p #{shared_path}/contenu/images &&
        #{try_sudo} mkdir -p #{shared_path}/contenu/videos &&
        #{try_sudo} mkdir -p #{shared_path}/contenu/son &&
        #{try_sudo} mkdir -p #{shared_path}/contenu/pdfs
      CMD
    end

    desc "[internal] Setup contao's localconfig"
    task :setup_localconfig, :roles => :app, :except => { :no_release => true } do
      localconfig = File.read("public/system/config/localconfig.php.sample")
      mysql_credentials = fetch :mysql_credentials

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

      put localconfig, "#{shared_path}/localconfig.php"
    end

    task :fix_links, :roles => :app, :except => { :no_release => true } do
      run <<-CMD
        #{try_sudo} rm -rf #{fetch :latest_release}/public/tl_files/durable/contenu &&
        #{try_sudo} rm -rf #{fetch :latest_release}/log &&
        #{try_sudo} ln -nsf #{fetch :shared_path}/contenu #{fetch :latest_release}/public/tl_files/durable/contenu &&
        #{try_sudo} ln -nsf #{fetch :shared_path}/htaccess.txt #{fetch :latest_release}/public/.htaccess &&
        #{try_sudo} ln -nsf #{fetch :shared_path}/localconfig.php #{fetch :latest_release}/public/system/config/localconfig.php &&
        #{try_sudo} ln -nsf #{fetch :shared_path}/log #{fetch :latest_release}/log
      CMD
    end
  end

  # Dependencies
  after "deploy:setup", "contao:setup"
  after "contao:setup", "contao:setup_localconfig"
  after "contao:setup_localconfig", "mysql:create_db"
  after "deploy:finalize_update", "contao:fix_links"
  after "contao:fix_links", "deploy:cleanup"
  after "deploy:restart", "deploy:fix_permissions"

  # Mysql Credentials
  before "contao:setup_localconfig", "mysql:credentials"
  before "contao:setup_db", "mysql:credentials"
end