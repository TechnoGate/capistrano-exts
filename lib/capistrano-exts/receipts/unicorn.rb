# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :unicorn do
    desc "[internal] Setup unicorn"
    task :setup, :roles => :app, :except => {:no_release => true} do
      unicorn_pid = fetch(:unicorn_pid, "#{fetch :shared_path}/pids/unicorn.pid")

      # Create the pids folder
      run <<-CMD
        #{try_sudo} mkdir -p #{File.dirname(fetch(:unicorn_pid))}
      CMD
    end

    desc "start unicorn"
    task :start, :roles => :app, :except => {:no_release => true} do
      unicorn_binary = fetch(:unicorn_binary, 'unicorn_rails')
      unicorn_config = fetch(:unicorn_config, "#{fetch :current_path}/config/unicorn.rb")
      rails_env = fetch(:rails_env, 'production')
      run "cd #{fetch :current_path} && #{try_bundle_exec} #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D"
    end

    desc "stop unicorn"
    task :stop, :roles => :app, :except => {:no_release => true} do
      unicorn_pid = fetch(:unicorn_pid, "#{fetch :shared_path}/pids/unicorn.pid")
      run "#{try_sudo} kill `cat #{unicorn_pid}`"
    end

    desc "unicorn reload"
    task :reload, :roles => :app, :except => {:no_release => true} do
      unicorn_pid = fetch(:unicorn_pid, "#{fetch :shared_path}/pids/unicorn.pid")
      run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
    end

    desc "graceful stop unicorn"
    task :graceful_stop, :roles => :app, :except => {:no_release => true} do
      unicorn_pid = fetch(:unicorn_pid, "#{fetch :shared_path}/pids/unicorn.pid")
      run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
    end

    desc "restart unicorn"
    task :restart, :roles => :app, :except => {:no_release => true} do
      stop
      start
    end
  end

  # Dependencies
  after "deploy:folders", "unicorn:setup"
end