# encoding: utf-8

require 'capistrano'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do
      namespace :web_server do
        namespace :apache do

          _cset :apache_init_path, "/etc/init.d/apache2"

          desc "[internal] Generate Apache configuration"
          task :generate_configuration do
            # TODO: Write this task
          end

          desc "Start apache web server"
          task :start do
            run <<-CMD
              #{try_sudo} #{fetch :apache_init_path} start
            CMD
          end

          desc "Stop apache web server"
          task :stop do
            run <<-CMD
              #{try_sudo} #{fetch :apache_init_path} stop
            CMD
          end

          desc "Restart apache web server"
          task :restart do
            run <<-CMD
              #{try_sudo} #{apache_init_path} restart
            CMD
          end

          desc "Resload apache web server"
          task :reload do
            run <<-CMD
              #{try_sudo} #{apache_init_path} reload
            CMD
          end

        end
      end
    end
  end
end