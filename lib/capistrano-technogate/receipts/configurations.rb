require 'capistrano'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

# Stolen from capistrano-ext/lib/capistrano/ext/multistage.rb
Capistrano::Configuration.instance.load do
  if exists?(:stages)
    on :load do
      if stages.include?(ARGV.first)
        # Execute the specified stage so that recipes required in stage can contribute to task list
        find_and_execute_task(ARGV.first) if ARGV.any?{ |option| option =~ /-T|--tasks|-e|--explain/ }
      else
        # Execute the default stage so that recipes required in stage can contribute tasks
        find_and_execute_task(default_stage) if exists?(:default_stage)
      end
    end

    # Define which stage should we run ?
    stages.each do |name|
      desc "Set the target stage to '#{name}'."
      task(name) do
        set :stage, name.to_sym
      end
    end

    namespace :multistage do
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

    on :start, "multistage:parse_configuration", except: stages
  end
end