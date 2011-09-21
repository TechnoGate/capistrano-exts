# This files has been copied over from capistrano-ext
# https://github.com/capistrano/capistrano-ext and has been modified
# To allow configuration in either seperate files or in-line configurations

require 'fileutils'

unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance.load do
  location = fetch(:stage_dir, "config/deploy")

  unless exists?(:stages)
    if exists?(:multistages)
      set :stages, fetch(:multistages).keys
    else
      set :stages, Dir["#{location}/*.rb"].map { |f| File.basename(f, ".rb") }
    end
  end

  stages.each do |name|
    desc "Set the target stage to `#{name}'."
    task(name) do
      set :stage, name.to_sym
      begin
        load "#{location}/#{stage}" unless exists?(:multistages)
      rescue LoadError
        abort "The file #{location}/#{stage} does not exist please run 'cap multistage:setup'"
      end
      find_and_execute_task('multistage:parse_multistages') if exists?(:multistages)
    end
  end

  on :load do
    if stages.include?(ARGV.first.to_sym)
      # Execute the specified stage so that recipes required in stage can contribute to task list
      find_and_execute_task(ARGV.first) if ARGV.any?{ |option| option =~ /-T|--tasks|-e|--explain/ }
    else
      # Execute the default stage so that recipes required in stage can contribute tasks
      find_and_execute_task(default_stage) if exists?(:default_stage)
    end
  end

  namespace :multistage do
    desc "[internal] Ensure that a stage has been selected."
    task :ensure do
      if !exists?(:stage)
        if exists?(:default_stage)
          logger.important "Defaulting to `#{default_stage}'"
          find_and_execute_task(default_stage)
        else
          abort "No stage specified. Please specify one of: #{stages.join(', ')} (e.g. `cap #{stages.first} #{ARGV.last}')"
        end
      end
    end

    desc "Stub out the staging config files."
    task :setup do
      FileUtils.mkdir_p(location)
      stages.each do |name|
        file = File.join(location, name.to_s + ".rb")
        unless File.exists?(file)
          File.open(file, "w") do |f|
            f.puts "# #{name.to_s.upcase}-specific deployment configuration"
            f.puts "# please put general deployment config in config/deploy.rb"
            f.puts ""
            f.write File.read(File.expand_path(File.join File.dirname(__FILE__), '..', 'templates', 'multistage.rb'))
          end

          logger.info "#{name} configurations has been written to #{file}, please open and edit it."
        end
      end
    end

    desc "[internal] Parse the configuration"
    task :parse_multistages do
      multistages = fetch :multistages
      stage = fetch :stage

      if multistages[stage].nil?
        abort "ERROR: '#{stage.to_s}' has not been configured yet, please open up 'config/deploy.rb' and configure it"
      end

      # Parse multistages
      multistages[stage].each { |config, value| set config, value }
    end

    namespace :sync do
      # Synchronisations tasks
      # Don't you just love metaprogramming? I know I fucking do!
      stages.each do |target_stage|
        stages.reject { |s| s == target_stage }.each do |source_stage|
          desc "Synchronise #{target_stage}'s database with #{source_stage}"
          task "#{target_stage}_database_with_#{source_stage}", :roles => :db, :except => { :no_release => true } do
            # Ask for a confirmation
            ask_for_confirmation "I am going to synchronise '#{target_stage}' database with '#{source_stage}', it means I will overwrite the database of '#{target_stage}' with those of '#{source_stage}', are you really sure you would like to continue (Yes, [No], Abort)", default:'N'

            # Generate a random folder name
            random_folder = random_tmp_file

            # Create the folder
            FileUtils.mkdir_p random_folder

            # Get the database of the source
            system "bundle exec cap #{source_stage} mysql:export_db_dump #{random_folder}/database.sql"

            # Send it to the target
            system "bundle exec cap -S force=true #{target_stage} mysql:import_db_dump #{random_folder}/database.sql"

            # Remove the entire folder
            FileUtils.rm_rf random_folder
          end

          desc "Synchronise #{target_stage}'s contents with #{source_stage}"
          task "#{target_stage}_contents_with_#{source_stage}", :roles => :app, :except => { :no_release => true } do
            # Ask for a confirmation
            ask_for_confirmation "I am going to synchronise '#{target_stage}' contents with '#{source_stage}', it means I will overwrite the contents of '#{target_stage}' with those of '#{source_stage}', are you really sure you would like to continue (Yes, [No], Abort)", default:'N'

            # Generate a random folder name
            random_folder = random_tmp_file

            # Create the folder
            FileUtils.mkdir_p random_folder

            # Get the contents of the source
            system "bundle exec cap #{source_stage} contents:export #{random_folder}/contents.tar.gz"

            # Send them to the target
            system "bundle exec cap -S force=true #{target_stage} contents:import #{random_folder}/contents.tar.gz"

            # Remove the entire folder
            FileUtils.rm_rf random_folder
          end

          desc "Synchronise #{target_stage} with #{source_stage}"
          task "#{target_stage}_with_#{source_stage}", :roles => [:app, :db], :except => { :no_release => true } do
            # Ask for a confirmation
            ask_for_confirmation "I am going to synchronise '#{target_stage}' with '#{source_stage}', it means I will overwrite both the database and the contents of '#{target_stage}' with those of '#{source_stage}', are you really sure you would like to continue (Yes, [No], Abort)", default:'N'

            # Synchronise the database
            system "bundle exec cap -S force=true multistage:sync:#{target_stage}_database_with_#{source_stage}"

            # Synchronise the contents
            system "bundle exec cap -S force=true multistage:sync:#{target_stage}_contents_with_#{source_stage}"
          end
        end
      end
    end
  end

  on :start, "multistage:ensure", :except => stages + ['multistage:setup', 'multistage:parse_multistages']
end