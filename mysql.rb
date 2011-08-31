require 'capistrano'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :mysql do
    desc "Backup database"
    task :backup_db do
      mysql_credentials = TechnoGate::Contao.instance.mysql_credentials
      mysql_db_name     = TechnoGate::Contao.instance.mysql_database_name
      MYSQL_DB_BACKUP_PATH = "#{deploy_to}/backups/#{mysql_db_name}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.sql"

      unless blank?(mysql_credentials)
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
      end
    end

    desc "drop database"
    task :drop_db do
      mysql_credentials = TechnoGate::Contao.instance.mysql_credentials
      mysql_db_name     = TechnoGate::Contao.instance.mysql_database_name

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
      mysql_credentials = TechnoGate::Contao.instance.mysql_credentials
      mysql_db_name     = TechnoGate::Contao.instance.mysql_database_name

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
      mysql_credentials = TechnoGate::Contao.instance.mysql_credentials
      mysql_db_name     = TechnoGate::Contao.instance.mysql_database_name

      unless ARGV.size >=2 and File.exists?(ARGV[1])
        puts "ERROR: please run 'cap mysql:import_db_dump <sql dump>'"
        exit 1
      else
        # The database dump name
        dump_sql_file = ARGV.delete_at(1)

        unless blank?(mysql_credentials)
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
      mysql_credentials = TechnoGate::Contao.instance.mysql_credentials
      mysql_db_name     = TechnoGate::Contao.instance.mysql_database_name

      unless ARGV.size >=2 or File.exists?(ARGV[1])
        puts "ERROR: please run 'cap mysql:import_db_dump <sql dump>'"
        puts "       <sql dump> should not exist"
        exit 1
      else
        # The database dump name
        dump_sql_file = ARGV.delete_at(1)

        unless blank?(mysql_credentials)
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
  end

  before "mysql:import_db_dump", "mysql:backup_db"
  before "mysql:export_db_dump", "mysql:backup_db"
end