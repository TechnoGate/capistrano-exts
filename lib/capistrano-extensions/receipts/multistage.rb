require 'capistrano'
require 'fileutils'

unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end

Capistrano::Configuration.instance.load do
  location = fetch(:stage_dir, "config/deploy")

  unless exists?(:stages)
    set :stages, Dir["#{location}/*.rb"].map { |f| File.basename(f, ".rb") }
  end

  stages.each do |name|
    desc "Set the target stage to `#{name}'."
    task(name) do
      set :stage, name.to_sym
      load "#{location}/#{stage}" unless exists?(:multistage)
      find_and_execute_task('multistage:parse_configuration') if exists?(:multistage)
    end
  end

  on :load do
    if stages.include?(ARGV.first)
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
    task :prepare do
      FileUtils.mkdir_p(location)
      stages.each do |name|
        file = File.join(location, name + ".rb")
        unless File.exists?(file)
          File.open(file, "w") do |f|
            f.puts "# #{name.upcase}-specific deployment configuration"
            f.puts "# please put general deployment config in config/deploy.rb"
          end
        end
      end
    end

    desc "Parse the configuration"
    task :parse_configuration do
      if configurations[stage].nil?
        abort "ERROR: '#{stage.to_s}' has not been configured yet, please open up 'config/deploy.rb' and configure it"
      end

      # Parse configurations
      configurations[stage].each { |config, value| set config, value }

      # Set the current path
      set :current_path, "#{File.join deploy_to, 'current'}"
    end
  end

  on :start, "multistage:ensure", :except => stages + ['multistage:prepare', 'multistage:parse_configuration']
end