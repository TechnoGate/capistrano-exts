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
      backup_path = fetch :backup_path, "#{fetch :deploy_to}/backups"

      set :latest_db_dump, "#{backup_path}/#{mysql_db_name}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.sql"
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
          logger.info "WARNING: The database doesn't exist."
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
          logger.info "WARNING: The database doesn't exist or you do not have permissions to drop it, trying to drop all tables inside of it."
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
            logger.info "WARNING: The database doesn't exist or you do not have permissions to drop it."
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

        # Upload the script
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
            host: fetch(:mysql_db_server, 'localhost'),
            user: mysql_db_user,
            pass: fetch(:mysql_db_pass),
          }

          find_and_execute_task("mysql:write_credentials")
        rescue Capistrano::CommandError
          logger.info "WARNING: The user #{application} already exists or you do not have permissions to create it."
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
          logger.info "WARNING: The database already exists or you do not have permissions to create it."
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
        logger.important "ERROR: please run 'cap mysql:import_db_dump <sql dump>'"
        exit 1
      else
        # The database dump name
        import_filename_argv = ARGV[argv_file_index]
        # Read the dump
        contents_dump = File.read(import_filename_argv)
        # Generate a random file
        random_file = random_tmp_file contents_dump
        # Add a rollback hook
        on_rollback { run "rm -f #{random_file}" }

        if mysql_credentials.present?
          # Ask for a confirmation
          ask_for_confirmation "I am going to replace the database of #{fetch :application} with the contents of #{import_filename_argv}, are you sure you would like to continue (Yes, [No], Abort)", default:'N'

          # Transfer the SQL file to the server
          # TODO: Try upload(filename, remote_file_name) function instead
          put contents_dump, random_file

          # Backup skiped tables
          find_and_execute_task "mysql:backup_skiped_tables"

          # Drop the database
          find_and_execute_task("mysql:drop_db")

          # Create the database
          find_and_execute_task("mysql:create_db")

          run <<-CMD
            mysql \
              --host='#{mysql_credentials[:host]}' \
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              --default-character-set=utf8 \
              '#{mysql_db_name}' < \
              #{random_file}
          CMD

          # Remove the uploaded file
          run <<-CMD
            rm -f '#{random_file}'
          CMD

          # Restore skiped tables
          find_and_execute_task "mysql:restore_skiped_tables"

          # Exit because capistrano will rollback, the next argument is a file name and not a task
          # TODO: Find a better solution!
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

        logger.info "Mysql dump has been downloaded to #{export_filename}"
        exit 0
      end
    end

    desc "[internal] Backup tables listed in skip_tables_on_import"
    task :backup_skiped_tables, :roles => :db, :except => { :no_release => true } do
      if exists?(:skip_tables_on_import)
        mysql_credentials = fetch :mysql_credentials
        # Generate a random file
        random_file = random_tmp_file
        # Set the random file so it can be accessed later
        set :backuped_skiped_tables_file, random_file
        # Add a rollback hook
        on_rollback { run "rm -f #{random_file}" }

        run <<-CMD
          #{try_sudo} touch #{random_file}
        CMD

        fetch(:skip_tables_on_import).each do |t|
          begin
            run <<-CMD
              #{try_sudo} mysqldump \
                --host='#{mysql_credentials[:host]}'\
                --user='#{mysql_credentials[:user]}' \
                --password='#{mysql_credentials[:pass]}' \
                --default-character-set=utf8 \
                '#{mysql_db_name}' '#{t}' >> \
                '#{random_file}'
            CMD
          rescue Capistrano::CommandError
            logger.info "WARNING: It seems the database does not have the table '#{t}', skipping it."
          end
        end
      end
    end

    desc "[internal] Restore tables listed in skip_tables_on_import"
    task :restore_skiped_tables, :roles => :db, :except => { :no_release => true } do
      if exists?(:skip_tables_on_import) && exists?(:backuped_skiped_tables_file)
        mysql_credentials = fetch :mysql_credentials
        backuped_skiped_tables_file = fetch :backuped_skiped_tables_file

        begin
          run <<-CMD
            mysql \
              --host='#{mysql_credentials[:host]}' \
              --user='#{mysql_credentials[:user]}' \
              --password='#{mysql_credentials[:pass]}' \
              --default-character-set=utf8 \
              '#{mysql_db_name}' < \
              #{backuped_skiped_tables_file}
          CMD

          run <<-CMD
            #{try_sudo} rm -f #{backuped_skiped_tables_file}
          CMD
        rescue
          abort "ERROR: I couldn't restore the tables defined in skip_tables_on_import"
        end
      end
    end

    ['credentials', 'root_credentials'].each do |var|
      desc "print database #{var.gsub(/_/, ' ')}"
      task "print_#{var}" do
        logger.trace credentials_formatted(fetch "mysql_#{var}".to_sym)
      end

      desc "[internal] write database #{var.gsub(/_/, ' ')}"
      task "write_#{var}" do
        unless exists?("mysql_#{var}_file".to_sym) and remote_file_exists?(fetch "mysql_#{var}_file".to_sym)
          mysql_credentials_file = fetch "mysql_#{var}_file".to_sym
          credentials_formatted_content = credentials_formatted(fetch "mysql_#{var}".to_sym)
          random_file = random_tmp_file(credentials_formatted_content)
          put credentials_formatted_content, random_file

          begin
            run <<-CMD
              #{try_sudo} cp #{random_file} #{mysql_credentials_file}; \
              #{try_sudo} rm -f #{random_file}
            CMD
          rescue Capistrano::CommandError
            logger.info "WARNING: Apparently you do not have permissions to write to #{mysql_credentials_file}."
            find_and_execute_task("mysql:print_#{var}")
          end
        else
          logger.info "WARNING: mysql_#{var}_file is not defined or it already exists on the server."
          find_and_execute_task("mysql:print_#{var}") unless ARGV.include?("mysql:print_#{var}")
        end
      end

      desc "Get Mysql #{var.gsub(/_/, ' ')}"
      task "#{var}", :roles => :app, :except => { :no_release => true } do
        unless exists?("mysql_#{var}".to_sym)
          # Fetch configs
          mysql_credentials_host_regex = fetch "mysql_#{var}_host_regex".to_sym
          mysql_credentials_host_regex_match = fetch "mysql_#{var}_host_regex_match".to_sym

          mysql_credentials_user_regex = fetch "mysql_#{var}_user_regex".to_sym
          mysql_credentials_user_regex_match = fetch "mysql_#{var}_user_regex_match".to_sym

          mysql_credentials_pass_regex = fetch "mysql_#{var}_pass_regex".to_sym
          mysql_credentials_pass_regex_match = fetch "mysql_#{var}_pass_regex_match".to_sym

          # We haven't got the credentials yet, look for them
          if exists?("mysql_#{var}_file".to_sym) and remote_file_exists?(fetch "mysql_#{var}_file".to_sym)
            mysql_credentials_file = fetch "mysql_#{var}_file".to_sym

            begin
              set "mysql_#{var}_file_contents".to_sym, read(mysql_credentials_file)
            rescue Capistrano::CommandError
              set "mysql_#{var}".to_sym, false
            end

            if exists?("mysql_#{var}_file_contents".to_sym)
              mysql_credentials_file_contents = fetch "mysql_#{var}_file_contents".to_sym

              unless mysql_credentials_file_contents.blank?
                mysql_credentials = {
                  adapter: 'mysql',
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
                        default: mysql_credentials.try(:[], :host) || fetch(:mysql_db_server, 'localhost'),
                        validate: /.+/),
              user: ask("What is the username used to access the database",
                        default: mysql_credentials.try(:[], :user) || ((var == 'credentials') ? fetch(:mysql_db_user) : nil),
                        validate: /.+/),
              pass: ask("What is the password used to access the database",
                        default: mysql_credentials.try(:[], :pass),
                        validate: /.+/,
                        echo: false),
            }
          end

          # Finally set it so it's available and write it to the server.
          if mysql_credentials[:user].present? and mysql_credentials[:pass].present?
            set "mysql_#{var}".to_sym, mysql_credentials
            find_and_execute_task("mysql:write_#{var}")
          end
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

  before "mysql:print_credentials", "mysql:credentials"
  before "mysql:print_root_credentials", "mysql:root_credentials"

  # Import_db_dump => backup/restore skiped_tables
  before "mysql:backup_skiped_tables", "mysql:credentials"
  before "mysql:restore_skiped_tables", "mysql:credentials"
end