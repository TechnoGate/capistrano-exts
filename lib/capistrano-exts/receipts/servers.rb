# encoding: utf-8

# Requirements
require 'capistrano'
require 'capistrano-exts/receipts/deploy'
require 'capistrano-exts/receipts/mysql'
require 'capistrano-exts/receipts/servers/web_server'
require 'capistrano-exts/receipts/servers/db_server'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do

      desc "Send SSH key"
      task :send_ssh_key do
        # Find out at which index the file is located ?
        argv_file_index = ARGV.index("deploy:server:send_ssh_key") + 1

        # The database dump name
        idrsa_filename_argv = ARGV.try(:[], argv_file_index)

        # Generate the file name
        if idrsa_filename_argv and not idrsa_filename_argv =~ /.+:.+/ and not File.exists?(idrsa_filename_argv)
          idrsa_filename = idrsa_filename_argv
        else
          idrsa_filename = "#{ENV['HOME']}/.ssh/id_rsa.pub"
        end

        if File.exists?(idrsa_filename)
          idrsa_filename_contents = File.read(idrsa_filename).chomp
          random_file = random_tmp_file idrsa_filename_contents

          run <<-CMD
            mkdir -p ~/.ssh &&
            touch ~/.ssh/authorized_keys &&
            echo '#{idrsa_filename_contents}' > #{random_file} &&
            cat #{random_file} >> ~/.ssh/authorized_keys &&
            rm -f #{random_file}
          CMD
        else
          abort "The id_rsa or id_dsa file '#{idrsa_filename}' does not exists."
        end
      end

      namespace :setup do
        desc "Prepare the server (database server, web server and folders)"
        task :default do
          # Empty task, server preparation goes into callbacks
        end

        task :folders, :roles => :app do
          # Use deploy:folders
          find_and_execute_task("deploy:folders")
        end

        task :finish do
          # Empty task for callbacks
        end

      end
    end
  end

  # Callbacks
  before "deploy:server:setup", "deploy:server:setup:folders"
  after  "deploy:server:setup", "deploy:server:setup:finish"

  after "deploy:server:setup:folders", "deploy:server:db_server:setup"
  after "deploy:server:setup:folders", "deploy:server:web_server:setup"
end