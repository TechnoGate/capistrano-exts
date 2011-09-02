require 'capistrano'
require 'capistrano-extensions/receipts/base'
require 'capistrano-extensions/receipts/mysql'

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
    task :setup, :roles => :web do
      run <<-CMD
        #{try_sudo} mkdir -p #{shared_path}/log &&
        #{try_sudo} mkdir -p #{shared_path}/contenu &&
        #{try_sudo} mkdir -p #{shared_path}/contenu/images &&
        #{try_sudo} mkdir -p #{shared_path}/contenu/videos &&
        #{try_sudo} mkdir -p #{shared_path}/contenu/son &&
        #{try_sudo} mkdir -p #{shared_path}/contenu/pdfs
      CMD
    end

    task :setup_localconfig, :roles => :web do
      localconfig = File.read("public/system/config/localconfig.php.sample")

      # Add MySQL credentials
      unless blank?(localconfig) or blank?(mysql_credentials)
        localconfig.gsub!(/#DB_USER#/, mysql_credentials[:user])
        localconfig.gsub!(/#DB_PASS#/, mysql_credentials[:pass])
        localconfig.gsub!(/#DB_NAME#/, mysql_db_name)
      end

      # localconfig
      if blank?(mysql_credentials)
        puts "WARNING: The mysql credential file can't be found, localconfig has just been copied from the sample file"
      end

      put localconfig, "#{shared_path}/localconfig.php"
    end

    task :setup_db, :roles => :db do
      unless blank?(mysql_credentials)
        begin
          run <<-CMD
            mysqladmin --user='#{mysql_credentials[:user]}' --password='#{mysql_credentials[:pass]}' create '#{mysql_db_name}'
          CMD
        rescue
          puts "WARNING: The database already exists, it hasn't been modified, drop it manually if necessary."
        end
      end
    end

    task :fix_links, :roles => :web do
      run <<-CMD
        #{try_sudo} rm -rf #{latest_release}/public/tl_files/durable/contenu &&
        #{try_sudo} rm -rf #{latest_release}/log &&
        #{try_sudo} ln -nsf #{shared_path}/contenu #{latest_release}/public/tl_files/durable/contenu &&
        #{try_sudo} ln -nsf #{shared_path}/htaccess.txt #{latest_release}/public/.htaccess &&
        #{try_sudo} ln -nsf #{shared_path}/localconfig.php #{latest_release}/public/system/config/localconfig.php &&
        #{try_sudo} ln -nsf #{shared_path}/log #{latest_release}/log
      CMD
    end

    task :fix_permissions, :roles => :web do
      run <<-CMD
        #{try_sudo} chown -R www-data:www-data #{deploy_to} &&
        #{try_sudo} chmod -R g+w #{latest_release}
      CMD
    end

    # desc "Copy master database to staging"
    # task :replicate_master_database, :roles => :web do
    #   mysql_master_db_name = mysql_db_name("master")
    #   mysql_staging_db_name = mysql_db_name("staging")
    #
    #   mysql_staging_db_backup_path = "#{configurations[:staging][:deploy_to]}/backups/#{mysql_staging_db_name}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.sql"
    #
    #   begin
    #     run <<-CMD
    #       mysqldump \
    #         --user='#{mysql_credentials[:user]}' \
    #         --password='#{mysql_credentials[:pass]}' \
    #         --default-character-set=utf8 \
    #         '#{mysql_staging_db_name}' > \
    #         '#{mysql_staging_db_backup_path}'
    #     CMD
    #
    #     run <<-CMD
    #       bzip2 -9 '#{mysql_staging_db_backup_path}'
    #     CMD
    #
    #     run <<-CMD
    #       mysqladmin --user='#{mysql_credentials[:user]}' --password='#{mysql_credentials[:pass]}' drop --force '#{mysql_staging_db_name}'
    #     CMD
    #   rescue
    #     puts "NOTICE: #{application}'s staging database does not exist, continuing under this assumption."
    #   end
    #
    #   run <<-CMD
    #     mysqladmin --user='#{mysql_credentials[:user]}' --password='#{mysql_credentials[:pass]}' create '#{mysql_staging_db_name}'
    #   CMD
    #
    #   run <<-CMD
    #     mysqldump \
    #       --user='#{mysql_credentials[:user]}' \
    #       --password='#{mysql_credentials[:pass]}' \
    #       --default-character-set=utf8 \
    #       '#{mysql_master_db_name}' > \
    #       '/tmp/#{mysql_master_db_name}.sql'
    #   CMD
    #
    #   run <<-CMD
    #     mysql \
    #       --user='#{mysql_credentials[:user]}' \
    #       --password='#{mysql_credentials[:pass]}' \
    #       --default-character-set=utf8 \
    #       '#{mysql_staging_db_name}' < \
    #       /tmp/#{mysql_master_db_name}.sql
    #   CMD
    #
    #   run <<-CMD
    #     rm -f '/tmp/#{mysql_master_db_name}.sql'
    #   CMD
    # end
    #
    # desc "Copy master contents to staging"
    # task :replicate_master_contents, :roles => :web do
    #   run <<-CMD
    #     cp -R #{configurations[:development][:deploy_to]}/shared/contenu #{configurations[:staging][:deploy_to]}/shared/
    #   CMD
    # end
  end

  # Dependencies
  after "deploy:setup", "contao:setup"
  after "contao:setup", "contao:setup_localconfig"
  after "contao:setup_localconfig", "contao:setup_db"
  after "deploy:finalize_update", "contao:fix_links"
  after "contao:fix_links", "deploy:cleanup"
  after "deploy:restart", "contao:fix_permissions"

  # Mysql Credentials
  before "contao:setup_localconfig", "mysql:credentials"
  before "contao:setup_db", "mysql:credentials"
  # before "contao:replicate_master_database", "mysql:credentials"

  # if branch == 'staging'
  #   before "deploy:restart", "contao:replicate_master_database"
  #   after "contao:replicate_master_database", "contao:replicate_master_contents"
  # end
end