require 'capistrano'
require 'capistrano/technogate/base'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  def mysql_db_name(local_branch = nil)
    local_branch ||= branch
    "#{application}_co_#{local_branch}"
  end

  namespace :mysql do
    desc "Backup database"
    task :backup_db do
      MYSQL_DB_BACKUP_PATH = "#{deploy_to}/backups/#{mysql_db_name}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.sql"

      if exists?(:mysql_credentials)
        begin
          run <<-CMD
            mysqldump \
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              --default-character-set=utf8 \
              '#{mysql_db_name}' > \
              '#{MYSQL_DB_BACKUP_PATH}'
          CMD

          run <<-CMD
            bzip2 -9 '#{MYSQL_DB_BACKUP_PATH}'
          CMD
        rescue
          puts "WARNING: The database doesn't exist."
        end
      else
        abort "MySQL credentials are empty"
      end
    end

    desc "drop database"
    task :drop_db do
      begin
        run <<-CMD
          mysqladmin --user='#{mysql_credentials[:user]}' --password='#{mysql_credentials[:pass]}' drop --force '#{mysql_db_name}'
        CMD
      rescue
        puts "WARNING: The database doesn't exist."
      end
    end

    desc "create database"
    task :create_db do
      begin
        run <<-CMD
          mysqladmin --user='#{mysql_credentials[:user]}' --password='#{mysql_credentials[:pass]}' create '#{mysql_db_name}'
        CMD
      rescue
        puts "WARNING: The database doesn't exist."
      end
    end

    desc "Import a database dump"
    task :import_db_dump do
      unless ARGV.size >=2 and File.exists?(ARGV[1])
        puts "ERROR: please run 'cap mysql:import_db_dump <sql dump>'"
        exit 1
      else
        # The database dump name
        dump_sql_file = ARGV.delete_at(1)

        if exists?(mysql_credentials)
          drop_db
          create_db
          put File.read(dump_sql_file), "/tmp/#{mysql_db_name}_dump.sql"

          run <<-CMD
            mysql \
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
    task :export_db_dump do
      unless ARGV.size >=2 or File.exists?(ARGV[1])
        puts "ERROR: please run 'cap mysql:import_db_dump <sql dump>'"
        puts "       <sql dump> should not exist"
        exit 1
      else
        # The database dump name
        dump_sql_file = ARGV.delete_at(1)

        if exists?(mysql_credentials)
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
    task :credentials do
      unless exists?(:mysql_credentials)
        # We haven't got the credentials yet, look for them
        if exists?(:mysql_credentials_file) and remote_file_exists?(mysql_credentials_file)
          begin
            set :mysql_credentials_file_contents, capture("cat #{mysql_credentials_file}")
          rescue
            set :mysql_credentials, false
          end

         if exists?(:mysql_credentials_file_contents)
            set :mysql_credentials, {
              user: mysql_credentials_file_contents.match(mysql_credentials_user_regex)[mysql_credentials_user_regex_match].chomp,
              pass: mysql_credentials_file_contents.match(mysql_credentials_pass_regex)[mysql_credentials_pass_regex_match].chomp,
            }
          end
        end

        # Verify that we got them!
        if !exists?(:mysql_credentials)
          set :mysql_credentials, {
            user: ask("What is the username used to access the database", default: nil, validate: /.+/),
            pass: ask("What is the password used to access the database", default: nil, validate: /.+/, echo: false),
          }
        end
      end
    end

    desc "Get Mysql root credentials"
    task :root_credentials do
      unless exists?(:mysql_root_credentials)
        # We haven't got the credentials yet, look for them
        if exists?(:mysql_root_credentials_file) and remote_file_exists?(mysql_root_credentials_file)
          begin
            set :mysql_root_credentials_file_contents, capture("cat #{mysql_root_credentials_file}")
          rescue
            set :mysql_root_credentials, false
          end

         if exists?(:mysql_root_credentials_file_contents)
            set :mysql_root_credentials, {
              user: mysql_root_credentials_file_contents.match(mysql_root_credentials_user_regex)[mysql_root_credentials_user_regex_match].chomp,
              pass: mysql_root_credentials_file_contents.match(mysql_root_credentials_pass_regex)[mysql_root_credentials_pass_regex_match].chomp,
            }
          end
        end

        # Verify that we got them!
        if !exists?(:mysql_root_credentials)
          set :mysql_root_credentials, {
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
end