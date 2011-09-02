# encoding: utf-8

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do
      namespace :web_server do
        desc "Setup web server"
        task :setup, :roles => :web do
          # Empty task, server preparation goes into callbacks
        end

        desc "Web configuration"
        task :web_configuration do
          case web_server_app
          when :nginx
            nginx_configuration
          when :apache
            apache_configuration
          else
            abort "I don't know how to build '#{web_server_app}' configuration."
          end
        end

        desc "Nginx authentification"
        task :nginx_authentification do
          local_passwd_file = "/tmp/#{application}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.crypt"

          if exists?(:web_server_authentification_credentials)
            contents = Array.new
            web_server_authentification_credentials.each do |credentials|
              if credentials[:password].is_a?(Proc)
                password = credentials[:password].call.crypt(gen_pass(8))
              else
                password = credentials[:password].crypt(gen_pass(8))
              end
              contents << "#{credentials[:user]}:#{password}"
            end

            set :web_server_authentification_file_contents, contents.join("\n")
          end
        end

        desc "Nginx configuration"
        task :nginx_configuration do
          nginx = Capistrano::TechnoGate::Server::Nginx.new web_server_mode

          nginx.application = application
          nginx.public_path = public_path
          nginx.logs_path   = logs_path
          nginx.application_url = application_url

          nginx.listen_port = web_server_listen_port if exists?(:web_server_listen_port)

          if exists?(:web_server_authentification_file)
            nginx.authentification_file = web_server_authentification_file
            run <<-CMD
              mkdir -p #{File.dirname web_server_authentification_file}
            CMD
            put web_server_authentification_file_contents, web_server_authentification_file
          end

          nginx.indexes = web_server_indexes if exists?(:web_server_indexes)

          if exists?(:web_server_mod_rewrite_simulation)
            nginx.mod_rewrite_simulation = web_server_mod_rewrite_simulation
          end

          if exists?(:php_fpm_host)
            nginx.php_fpm_host = php_fpm_host
            nginx.php_fpm_port = php_fpm_port
          end

          set :nginx, nginx
          set :nginx_conf, nginx.render
        end

        desc "Write nginx configuration file"
        task :write_conf_file do
          run <<-CMD
            mkdir -p #{File.dirname nginx_conf_file}
          CMD

          put nginx_conf, nginx_conf_file
        end

      end
    end
  end

  after "deploy:server:web_server:setup", "deploy:server:web_server:web_configuration"
  before "deploy:server:web_server:nginx_configuration", "deploy:server:web_server:nginx_authentification"
end