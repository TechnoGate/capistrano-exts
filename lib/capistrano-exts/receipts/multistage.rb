# This files has been copied over from capistrano-ext
# https://github.com/capistrano/capistrano-ext and has been modified
# To allow configuration in either seperate files or in-line configurations

require 'capistrano'
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

          puts "#{name} configurations has been written to #{file}, please open and edit it."
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
  end

  on :start, "multistage:ensure", :except => stages + ['multistage:setup', 'multistage:parse_multistages']
end