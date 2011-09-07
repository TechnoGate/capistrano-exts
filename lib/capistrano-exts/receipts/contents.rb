require 'capistrano'
require 'capistrano/errors'
require 'capistrano-exts/receipts/functions'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :contents do
    desc "Setup the contents folder"
    task :setup, :roles => :app, :except => { :no_release => true } do
      shared_path = fetch :shared_path
      contents_folder = fetch :contents_folder

      run <<-CMD
        #{try_sudo} mkdir -p #{shared_path}/shared_contents
      CMD

      contents_folder.each do |folder, path|
        run <<-CMD
          #{try_sudo} mkdir -p #{shared_path}/shared_contents/#{folder}
        CMD
      end
    end

    desc "Backup the contents folder"
    task :backup, :roles => :app, :except => { :no_release => true } do
      backup_path = fetch :backup_path, "#{fetch :deploy_to}/backups"
      set :latest_contents_backup, "#{backup_path}/#{application}_shared_contents_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.tar.gz"
      latest_contents_backup = fetch :latest_contents_backup

      # Setup a rollback hook
      on_rollback { run "rm -f #{latest_contents_backup}" }

      # Create a tarball of the contents folder
      run <<-CMD
        cd #{shared_path}/shared_contents &&
        tar chzf #{latest_contents_backup} --exclude='*~' --exclude='*.tmp' --exclude='*.bak' *
      CMD
    end

    desc "[internal] Fix contao's symlinks to the shared path"
    task :fix_links, :roles => :app, :except => { :no_release => true } do
      contents_folder = fetch :contents_folder
      current_path = fetch :current_path
      latest_release = fetch :latest_release
      shared_path = fetch :shared_path

      contents_folder.each do |folder, path|
        # At this point, the current_path does not exists and by running an mkdir
        # later, we're actually breaking stuff.
        # So replace current_path with latest_release in the contents_path string
        path.gsub! %r{#{current_path}}, latest_release

        # Remove the path, making sure it does not exists
        run <<-CMD
          #{try_sudo} rm -f #{path}
        CMD

        # Make sure we have the folder that'll contain the shared path
        run <<-CMD
          #{try_sudo} mkdir -p #{File.dirname(path)}
        CMD

        # Create the symlink
        run <<-CMD
          #{try_sudo} ln -nsf #{shared_path}/shared_contents/#{folder} #{path}
        CMD
      end
    end

    desc "Export the contents folder"
    task :export, :roles => :app, :except => { :no_release => true } do
      shared_path = fetch :shared_path
      latest_contents_backup = fetch :latest_contents_backup

      # Find out at which index the file is located ?
      argv_file_index = ARGV.index("contents:export") + 1

      # The database dump name
      export_filename_argv = ARGV.try(:[], argv_file_index)

      # Generate the file name
      if export_filename_argv and not export_filename_argv =~ /.+:.+/ and not File.exists?(export_filename_argv)
        export_filename = export_filename_argv
      else
        export_filename = random_tmp_file + ".tar.gz"
      end

      # Tranfer the contents to the local system
      get latest_contents_backup, export_filename

      puts "Contents has been downloaded to #{export_filename}"
      exit 0
    end

    desc "Import the contents folder"
    task :import, :roles => :app, :except => { :no_release => true } do
      # Find out at which index the file is located ?
      argv_file_index = ARGV.index("contents:import") + 1

      unless ARGV.size >= (argv_file_index + 1) and File.exists?(ARGV[argv_file_index])
        puts "ERROR: please run 'cap import <gzipped tar>'"
        exit 1
      else
        # The contents file name
        import_filename_argv = ARGV[argv_file_index]
        # Read the dump
        contents_dump = File.read(import_filename_argv)
        # Generate a random file
        random_file = random_tmp_file contents_dump
        # Add a rollback hook
        on_rollback { run "rm -f #{random_file}" }

        # Ask for a confirmation
        response = ask("I am going to add/replace all the files in the contents folder of #{fetch :application} with the contents of #{import_filename_argv}, are you sure you would like to continue (Yes, [No], Abort)", default:'N')
        if response =~ /(no?)|(a(bort)?|\n)/i
          abort "Canceled by the user."
        end

        # Transfer the SQL file to the server
        # TODO: Try upload(filename, remote_file_name) function instead
        put contents_dump, random_file

        run <<-CMD
          cd #{shared_path}/shared_contents &&
          tar xzf #{random_file}
        CMD

        # Remove the uploaded file
        run <<-CMD
          rm -f '#{random_file}'
        CMD

        # Fix permissions
        find_and_execute_task("deploy:fix_permissions")

        # Exit because capistrano will rollback, the next argument is a file name and not a task
        # TODO: Find a better solution!
        exit 0
      end
    end
  end

  after "deploy:setup", "contents:setup"
  after "deploy:finalize_update", "contents:fix_links"
  before "contents:export", "contents:backup"
  before "contents:import", "contents:backup"
end