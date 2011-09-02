require 'capistrano'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :god do
    desc "start god, this starts up unicorn server"
    task :start, :roles => :web, :except => {:no_release => true} do
      run "cd #{current_path} && #{god_binary} -c #{god_config} --log /var/log/god.log --no-syslog --log-level warn"
    end

    desc "stop god, this shutdowns unicorn server"
    task :stop, :roles => :web, :except => {:no_release => true} do
      run "cd #{current_path} && #{god_binary} terminate"
    end

    desc "restart god, this restarts the unicorn server"
    task :restart, :roles => :web, :except => {:no_release => true} do
      run "cd #{current_path} && #{god_binary} restart"
    end

    desc "check if god is already running"
    task :check_if_running, :roles => :web, :except => {:no_release => true} do
      'true' ==  capture("if #{god_binary} status; then echo 'true'; fi").strip
    end
  end
end