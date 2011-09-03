require 'capistrano'
require 'capistrano-exts/receipts/deploy'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :mysql do
    desc "Backup database"
    task :backup_db, :roles => :db, :except => { :no_release => true } do
      mysql_credentials = fetch :mysql_credentials
      MYSQL_DB_BACKUP_PATH = "#{deploy_to}/backups/#{mysql_db_name}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.sql"

      if exists?(:mysql_credentials)
        begin
          run <<-CMD
            #{try_sudo} mysqldump \
              --host='#{mysql_credentials[:host]}'\
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              --default-character-set=utf8 \
              '#{mysql_db_name}' > \
              '#{MYSQL_DB_BACKUP_PATH}'
          CMD

          run <<-CMD
            #{try_sudo} bzip2 -9 '#{MYSQL_DB_BACKUP_PATH}'
          CMD
        rescue
          puts "WARNING: The database doesn't exist."
        end
      else
        abort "MySQL credentials are empty"
      end
    end

    desc "drop database"
    task :drop_db, :roles => :db, :except => { :no_release => true } do
      mysql_credentials = fetch :mysql_credentials

      unless mysql_credentials.blank?
        begin
          run <<-CMD
            mysqladmin \
              --host='#{mysql_credentials[:host]}' \
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              drop --force \
              '#{mysql_db_name}'
          CMD
        rescue
          puts "WARNING: The database doesn't exist."
        end
      end
    end

    desc "create database user"
    task :create_db_user, :roles => :db, :except => { :no_release => true } do
      mysql_root_credentials = fetch :mysql_root_credentials
      random_file = random_tmp_file mysql_root_credentials[:pass]

      unless mysql_root_credentials.blank?
        set :mysql_db_pass, -> { gen_pass(8) }
        mysql_create = ""

        mysql_db_hosts.each do |host|
          mysql_create << <<-EOS
            CREATE USER '#{mysql_db_user}'@'#{host}' IDENTIFIED BY '#{fetch :mysql_db_pass}';
            GRANT ALL ON `#{fetch :application}\_%`.* TO '#{mysql_db_user}'@'#{host}';
            FLUSH PRIVILEGES;
          EOS
        end

        put mysql_create, random_file

        begin
          run <<-CMD
            mysql \
              --host='#{mysql_root_credentials[:host]}' \
              --user='#{mysql_root_credentials[:user]}' \
              --password='#{mysql_root_credentials[:pass]}' \
              --default-character-set=utf8 < \
              #{random_file}
          CMD

          run <<-CMD
            rm -f #{random_file}
          CMD

          find_and_execute_task("mysql:write_db_credentials")
        rescue
          puts "WARNING: The user #{application} already exists."
          find_and_execute_task("mysql:print_db_credentials")
        end
      end
    end

    desc "write database credentials"
    task :write_db_credentials do
      mysql_credentials_file = fetch :mysql_credentials_file
      unless exists?(:mysql_credentials_file) and remote_file_exists?(mysql_credentials_file)
          put mysql_credentials, mysql_credentials_file
      end
    end

    desc "print database credentials"
    task :print_db_credentials do
      mysql_credentials_file = fetch :mysql_credentials_file
      unless exists?(:mysql_credentials_file) and remote_file_exists?(mysql_credentials_file)
        puts "WARNING: mysql_credentials_file is not defined in config.rb you have to manually copy the following info into a credential file and define it"
        puts mysql_credentials
      end
    end

    desc "create database"
    task :create_db, :roles => :db, :except => { :no_release => true } do
      mysql_credentials = fetch :mysql_credentials

      unless mysql_credentials.blank?
        begin
          run <<-CMD
            mysqladmin \
              --host='#{mysql_credentials[:host]}' \
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              create '#{mysql_db_name}'
          CMD
        rescue
          puts "WARNING: The database already exists, it hasn't been modified, drop it manually if necessary."
        end
      end
    end

    desc "Import a database dump"
    task :import_db_dump, :roles => :db, :except => { :no_release => true } do
      mysql_credentials = fetch :mysql_credentials

      unless ARGV.size >=2 and File.exists?(ARGV[1])
        puts "ERROR: please run 'cap mysql:import_db_dump <sql dump>'"
        exit 1
      else
        # The database dump name
        dump_sql_file = ARGV.delete_at(1)

        if mysql_credentials.present?
          drop_db
          create_db
          put File.read(dump_sql_file), "/tmp/#{mysql_db_name}_dump.sql"

          run <<-CMD
            mysql \
              --host='#{mysql_credentials[:host]}' \
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              --default-character-set=utf8 \
              '#{mysql_db_name}' < \
              /tmp/#{mysql_db_name}_dump.sql
          CMD

          run <<-CMD
            rm -f '/tmp/#{mysql_db_name}_dump.sql'
          CMD

          exit 0
        end
      end
    end

    desc "Export a database dump"
    task :export_db_dump, :roles => :db, :except => { :no_release => true } do
      mysql_credentials = fetch :mysql_credentials

      unless ARGV.size >=2 or File.exists?(ARGV[1])
        puts "ERROR: please run 'cap mysql:import_db_dump <sql dump>'"
        puts "       <sql dump> should not exist"
        exit 1
      else
        # The database dump name
        dump_sql_file = ARGV.delete_at(1)

        if mysql_credentials.present?
          run <<-CMD
            cp #{MYSQL_DB_BACKUP_PATH}.bz2 /tmp &&
            bunzip2 /tmp/#{File.basename MYSQL_DB_BACKUP_PATH}.bz2
          CMD

          get "/tmp/#{File.basename MYSQL_DB_BACKUP_PATH}", dump_sql_file

          run <<-CMD
            rm -f /tmp/#{File.basename MYSQL_DB_BACKUP_PATH}
          CMD

          exit 0
        end
      end
    end

    desc "Get Mysql credentials"
    task :credentials, :roles => :app, :except => { :no_release => true } do
      mysql_credentials_file = fetch :mysql_credentials_file

      unless exists?(:mysql_credentials)
        # We haven't got the credentials yet, look for them
        if exists?(:mysql_credentials_file) and remote_file_exists?(mysql_credentials_file)
          begin
            set :mysql_credentials_file_contents, capture("cat #{mysql_credentials_file}")
          rescue
            set :mysql_credentials, false
          end

          if exists?(:mysql_credentials_file_contents)
            mysql_credentials_file_contents = fetch :mysql_credentials_file_contents

            unless mysql_credentials_file_contents.blank?
              set :mysql_credentials, {
                host: mysql_credentials_file_contents.match(mysql_credentials_host_regex).try(:[], mysql_credentials_host_regex_match).try(:chomp),
                user: mysql_credentials_file_contents.match(mysql_credentials_user_regex).try(:[], mysql_credentials_user_regex_match).try(:chomp),
                pass: mysql_credentials_file_contents.match(mysql_credentials_pass_regex).try(:[], mysql_credentials_pass_regex_match).try(:chomp),
              }
            end
          end
        end

        # Verify that we got them!
        if !exists?(:mysql_credentials)
          set :mysql_credentials, {
            host: ask("What is the hostname used to access the database", default: 'localhost', validate: /.+/),
            user: ask("What is the username used to access the database", default: nil, validate: /.+/),
            pass: ask("What is the password used to access the database", default: nil, validate: /.+/, echo: false),
          }
        end
      end
    end

    desc "Get Mysql root credentials"
    task :root_credentials, :roles => :app, :except => { :no_release => true } do
      mysql_root_credentials_file = fetch :mysql_root_credentials_file

      unless exists?(:mysql_root_credentials)
        # We haven't got the credentials yet, look for them
        if exists?(:mysql_root_credentials_file) and remote_file_exists?(mysql_root_credentials_file)
          begin
            set :mysql_root_credentials_file_contents, capture("cat #{mysql_root_credentials_file}")
          rescue
            set :mysql_root_credentials, false
          end

          if exists?(:mysql_root_credentials_file_contents)
            mysql_root_credentials_file_contents = fetch :mysql_root_credentials_file_contents
            unless mysql_root_credentials_file_contents.blank?
              set :mysql_root_credentials, {
                host: mysql_root_credentials_file_contents.match(mysql_root_credentials_host_regex).try(:[], mysql_root_credentials_host_regex_match).try(:chomp),
                user: mysql_root_credentials_file_contents.match(mysql_root_credentials_user_regex).try(:[], mysql_root_credentials_user_regex_match).try(:chomp),
                pass: mysql_root_credentials_file_contents.match(mysql_root_credentials_pass_regex).try(:[], mysql_root_credentials_pass_regex_match).try(:chomp),
              }
            end
          end
        end

        # Verify that we got them!
        if !exists?(:mysql_root_credentials)
          set :mysql_root_credentials, {
            host: ask("What is the hostname used to access the database", default: 'localhost', validate: /.+/),
            user: ask("What is the username used to access the database", default: nil, validate: /.+/),
            pass: ask("What is the password used to access the database", default: nil, validate: /.+/, echo: false),
          }
        end
      end
    end
  end

  before "mysql:backup_db", "mysql:credentials"
  before "mysql:drop_db", "mysql:credentials"
  before "mysql:create_db", "mysql:credentials"
  before "mysql:import_db_dump", "mysql:backup_db"
  before "mysql:export_db_dump", "mysql:backup_db"
  before "mysql:create_db_user", "mysql:root_credentials"
  after  "mysql:create_db_user", "mysql:create_db"
end