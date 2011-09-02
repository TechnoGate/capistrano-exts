require 'capistrano'
require 'highline'
require 'capistrano-extensions/receipts/base'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    desc "Check if the branch is ready"
    task :check_if_branch_is_ready, :roles => :app, :except => { :no_release => true } do
      unless `git rev-parse #{branch}` == `git rev-parse origin/#{branch}`
        puts "ERROR: #{branch} is not the same as origin/#{branch}"
        puts "Run `git push` to sync changes."
        exit
      end
    end

    desc "Check if this revision has already been deployed."
    task :check_revision, :roles => :app, :except => { :no_release => true } do
      if remote_file_exists?("#{deploy_to}/current/REVISION")
        if `git rev-parse #{branch}`.strip == capture("cat #{deploy_to}/current/REVISION").strip
          response = ask("The verison you are trying to deploy is already deployed, should I continue (Yes, [No], Abort)", default: 'No')
          if response =~ /(no?)|(a(bort)?|\n)/i
            abort "Canceled by the user."
          end
        end
      end
    end
  end

  # Dependencies
  before "deploy", "deploy:check_if_branch_is_ready"
  after "deploy:check_if_branch_is_ready", "deploy:check_revision"
end