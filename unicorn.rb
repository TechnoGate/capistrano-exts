namespace :unicorn do
  desc "start unicorn"
  task :start, :roles => :app, :except => {:no_release => true} do
    run "cd #{current_path} && #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D"
  end

  desc "stop unicorn"
  task :stop, :roles => :app, :except => {:no_release => true} do
    run "#{try_sudo} kill `cat #{unicorn_pid}`"
  end

  desc "unicorn reload"
  task :reload, :roles => :app, :except => {:no_release => true} do
    run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
  end

  desc "graceful stop unicorn"
  task :graceful_stop, :roles => :app, :except => {:no_release => true} do
    run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
  end

  desc "restart unicorn"
  task :restart, :roles => :app, :except => {:no_release => true} do
    stop
    start
  end
end