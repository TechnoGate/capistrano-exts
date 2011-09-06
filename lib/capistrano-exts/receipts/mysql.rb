require 'capistrano'
require 'capistrano/errors'
require 'capistrano-exts/receipts/functions'
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
      mysql_db_name = fetch :mysql_db_name
      deploy_to = fetch :deploy_to
      set :latest_db_dump, "#{deploy_to}/backups/#{mysql_db_name}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.sql"
      latest_db_dump = fetch :latest_db_dump

      on_rollback { run "rm -f #{latest_db_dump}" }

      if exists?(:mysql_credentials)
        begin
          run <<-CMD
            #{try_sudo} mysqldump \
              --host='#{mysql_credentials[:host]}'\
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              --default-character-set=utf8 \
              '#{mysql_db_name}' > \
              '#{latest_db_dump}'
          CMD

          run <<-CMD
            #{try_sudo} bzip2 -9 '#{latest_db_dump}'
          CMD
        rescue Capistrano::CommandError
          puts "WARNING: The database doesn't exist."
        end
      else
        abort "MySQL credentials are empty"
      end
    end

    desc "drop database"
    task :drop_db, :roles => :db, :except => { :no_release => true } do
      mysql_credentials = fetch :mysql_credentials
      mysql_db_name = fetch :mysql_db_name

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
        rescue Capistrano::CommandError
          puts "WARNING: The database doesn't exist or you do not have permissions to drop it, trying to drop all tables inside of it."
          begin
            run <<-CMD
              mysqldump \
                --host='#{mysql_credentials[:host]}' \
                --user='#{mysql_credentials[:user]}' \
                --password='#{mysql_credentials[:pass]}' \
                --add-drop-table --no-data '#{mysql_db_name}' |\
                grep '^DROP' | \
                mysql \
                --host='#{mysql_credentials[:host]}' \
                --user='#{mysql_credentials[:user]}' \
                --password='#{mysql_credentials[:pass]}' \
                '#{mysql_db_name}'
            CMD
          rescue Capistrano::CommandError
            puts "WARNING: The database doesn't exist or you do not have permissions to drop it."
          end
        end
      end
    end

    desc "create database user"
    task :create_db_user, :roles => :db, :except => { :no_release => true } do
      mysql_root_credentials = fetch :mysql_root_credentials
      mysql_db_user = fetch :mysql_db_user
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

          set :mysql_credentials, {
            host: find_servers(:roles => :db, primary: true).first.to_s.gsub(/^(.*@)?([^:]*)(:.*)?$/, '\2'),
            user: mysql_db_user,
            pass: fetch(:mysql_db_pass),
          }

          find_and_execute_task("mysql:write_credentials")
        rescue Capistrano::CommandError
          puts "WARNING: The user #{application} already exists or you do not have permissions to create it."
          find_and_execute_task("mysql:print_credentials")
        end
      end
    end

    desc "create database"
    task :create_db, :roles => :db, :except => { :no_release => true } do
      mysql_credentials = fetch :mysql_credentials
      mysql_db_name = fetch :mysql_db_name

      unless mysql_credentials.blank?
        begin
          run <<-CMD
            mysqladmin \
              --host='#{mysql_credentials[:host]}' \
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              create '#{mysql_db_name}'
          CMD
        rescue Capistrano::CommandError
          puts "WARNING: The database already exists or you do not have permissions to create it."
        end
      end
    end

    desc "Import a database dump"
    task :import_db_dump, :roles => :db, :except => { :no_release => true } do
      mysql_credentials = fetch :mysql_credentials
      mysql_db_name = fetch :mysql_db_name

      # Find out at which index the file is located ?
      argv_file_index = ARGV.index("mysql:import_db_dump") + 1

      unless ARGV.size >= (argv_file_index + 1) and File.exists?(ARGV[argv_file_index])
        puts "ERROR: please run 'cap mysql:import_db_dump <sql dump>'"
        exit 1
      else
        # The database dump name
        import_filename_argv = ARGV[argv_file_index]
        # Read the dump
        mysql_dump = File.read(import_filename_argv)
        # Generate a random file
        random_file = random_tmp_file mysql_dump
        # Add a rollback hook
        on_rollback { run "rm -f #{random_file}" }

        if mysql_credentials.present?
          drop_db
          create_db
          put File.read(import_filename_argv), random_file

          run <<-CMD
            mysql \
              --host='#{mysql_credentials[:host]}' \
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              --default-character-set=utf8 \
              '#{mysql_db_name}' < \
              #{random_file}
          CMD

          run <<-CMD
            rm -f '#{random_file}'
          CMD

          exit 0
        end
      end
    end

    desc "Export a database dump"
    task :export_db_dump, :roles => :db, :except => { :no_release => true } do
      latest_db_dump = fetch :latest_db_dump
      on_rollback { run "rm -f /tmp/#{File.basename latest_db_dump}{,.bz2" }

      mysql_credentials = fetch :mysql_credentials

      # Find out at which index the file is located ?
      argv_file_index = ARGV.index("mysql:export_db_dump") + 1

      # The database dump name
      export_filename_argv = ARGV.try(:[], argv_file_index)

      # Generate the file name
      if export_filename_argv and not export_filename_argv =~ /.+:.+/ and not File.exists?(export_filename_argv)
        export_filename = export_filename_argv
      else
        export_filename = random_tmp_file + ".sql"
      end

      # Get the dump
      if mysql_credentials.present?
        run <<-CMD
          cp #{latest_db_dump}.bz2 /tmp &&
          bunzip2 /tmp/#{File.basename latest_db_dump}.bz2
        CMD

        get "/tmp/#{File.basename latest_db_dump}", export_filename

        run <<-CMD
          rm -f /tmp/#{File.basename latest_db_dump}
        CMD

        puts "Mysql dump has been downloaded to #{export_filename}"
        exit 0
      end
    end

    # TODO: credentials and root_credentials are exactly the same code with
    #       one variable changing, we need some meta-programming for them!!

    desc "print database credentials"
    task :print_credentials do
      puts mysql_credentials_formatted(fetch :mysql_credentials)
    end

    desc "[internal] write database credentials"
    task :write_credentials do
      unless exists?(:mysql_credentials_file) and remote_file_exists?(fetch :mysql_credentials_file)
        mysql_credentials_file = fetch :mysql_credentials_file
        random_file = random_tmp_file(mysql_credentials_formatted(fetch :mysql_credentials))
        put mysql_credentials_formatted(fetch :mysql_credentials), random_file

        begin
          run <<-CMD
            #{try_sudo} cp #{random_file} #{mysql_credentials_file}; \
            #{try_sudo} rm -f #{random_file}
          CMD
        rescue Capistrano::CommandError
          puts "WARNING: Apparently you do not have permissions to write to #{mysql_credentials_file}."
          find_and_execute_task("mysql:print_credentials")
        end
      else
        puts "WARNING: mysql_credentials_file is not defined or it already exists on the server."
        find_and_execute_task("mysql:print_credentials")
      end
    end

    desc "Get Mysql credentials"
    task :credentials, :roles => :app, :except => { :no_release => true } do
      unless exists?(:mysql_credentials)
        # We haven't got the credentials yet, look for them
        if exists?(:mysql_credentials_file) and remote_file_exists?(fetch :mysql_credentials_file)
          mysql_credentials_file = fetch :mysql_credentials_file

          begin
            set :mysql_credentials_file_contents, capture("cat #{mysql_credentials_file}")
          rescue Capistrano::CommandError
            set :mysql_credentials, false
          end

          if exists?(:mysql_credentials_file_contents)
            mysql_credentials_file_contents = fetch :mysql_credentials_file_contents

            unless mysql_credentials_file_contents.blank?
              mysql_credentials = {
                host: mysql_credentials_file_contents.match(mysql_credentials_host_regex).try(:[], mysql_credentials_host_regex_match).try(:chomp),
                user: mysql_credentials_file_contents.match(mysql_credentials_user_regex).try(:[], mysql_credentials_user_regex_match).try(:chomp),
                pass: mysql_credentials_file_contents.match(mysql_credentials_pass_regex).try(:[], mysql_credentials_pass_regex_match).try(:chomp),
              }
            end
          end
        end

        # Verify that we got them!
        if mysql_credentials.blank? or mysql_credentials[:user].blank? or mysql_credentials[:pass].blank?
          mysql_credentials = {
            host: ask("What is the hostname used to access the database",
                      default: mysql_credentials.try(:[], :host) || 'localhost',
                      validate: /.+/),
            user: ask("What is the username used to access the database",
                      default: mysql_credentials.try(:[], :user),
                      validate: /.+/),
            pass: ask("What is the password used to access the database",
                      default: mysql_credentials.try(:[], :pass),
                      validate: /.+/,
                      echo: false),
          }
        end

        # Finally set it so it's available and write it to the server.
        if mysql_credentials[:user].present? and mysql_credentials[:pass].present?
          set :mysql_credentials, mysql_credentials
          find_and_execute_task("mysql:write_credentials")
        end
      end
    end

    # REFACTOR!!
    desc "print database root credentials"
    task :print_root_credentials do
      puts mysql_credentials_formatted(fetch :mysql_root_credentials)
    end

    desc "[internal] write database root credentials"
    task :write_root_credentials do
      unless exists?(:mysql_root_credentials_file) and remote_file_exists?(fetch :mysql_root_credentials_file)
        mysql_root_credentials_file = fetch :mysql_root_credentials_file
        random_file = random_tmp_file(mysql_credentials_formatted(fetch :mysql_root_credentials))
        put mysql_credentials_formatted(fetch :mysql_root_credentials), random_file

        begin
          run <<-CMD
            #{try_sudo} cp #{random_file} #{mysql_root_credentials_file}; \
            #{try_sudo} rm -f #{random_file}
          CMD
        rescue Capistrano::CommandError
          puts "WARNING: Apparently you do not have permissions to write to #{mysql_root_credentials_file}."
          find_and_execute_task("mysql:print_root_credentials")
        end
      else
        puts "WARNING: mysql_root_credentials_file is not defined or it already exists on the server."
        find_and_execute_task("mysql:print_root_credentials")
      end
    end

    desc "Get Mysql root_credentials"
    task :root_credentials, :roles => :app, :except => { :no_release => true } do
      unless exists?(:mysql_root_credentials)
        # We haven't got the root_credentials yet, look for them
        if exists?(:mysql_root_credentials_file) and remote_file_exists?(fetch :mysql_root_credentials_file)
          mysql_root_credentials_file = fetch :mysql_root_credentials_file

          begin
            set :mysql_root_credentials_file_contents, capture("cat #{mysql_root_credentials_file}")
          rescue Capistrano::CommandError
            set :mysql_root_credentials, false
          end

          if exists?(:mysql_root_credentials_file_contents)
            mysql_root_credentials_file_contents = fetch :mysql_root_credentials_file_contents

            unless mysql_root_credentials_file_contents.blank?
              mysql_root_credentials = {
                host: mysql_root_credentials_file_contents.match(mysql_root_credentials_host_regex).try(:[], mysql_root_credentials_host_regex_match).try(:chomp),
                user: mysql_root_credentials_file_contents.match(mysql_root_credentials_user_regex).try(:[], mysql_root_credentials_user_regex_match).try(:chomp),
                pass: mysql_root_credentials_file_contents.match(mysql_root_credentials_pass_regex).try(:[], mysql_root_credentials_pass_regex_match).try(:chomp),
              }
            end
          end
        end

        # Verify that we got them!
        if mysql_root_credentials.blank? or mysql_root_credentials[:user].blank? or mysql_root_credentials[:pass].blank?
          mysql_root_credentials = {
            host: ask("What is the hostname used to access the database",
                      default: mysql_root_credentials.try(:[], :host) || 'localhost',
                      validate: /.+/),
            user: ask("What is the username used to access the database",
                      default: mysql_root_credentials.try(:[], :user),
                      validate: /.+/),
            pass: ask("What is the password used to access the database",
                      default: mysql_root_credentials.try(:[], :pass),
                      validate: /.+/,
                      echo: false),
          }
        end

        # Finally set it so it's available and write it to the server.
        if mysql_root_credentials[:user].present? and mysql_root_credentials[:pass].present?
          set :mysql_root_credentials, mysql_root_credentials
          find_and_execute_task("mysql:write_root_credentials")
        end
      end
    end
    # REFACTOR!!

  end

  before "mysql:backup_db", "mysql:credentials"
  before "mysql:drop_db", "mysql:credentials"
  before "mysql:create_db", "mysql:credentials"
  before "mysql:import_db_dump", "mysql:backup_db"
  before "mysql:export_db_dump", "mysql:backup_db"
  before "mysql:create_db_user", "mysql:root_credentials"
  after  "mysql:create_db_user", "mysql:create_db"

  before "mysql:print_credentials", "mysql:credentials"
  before "mysql:print_root_credentials", "mysql:root_credentials"
end