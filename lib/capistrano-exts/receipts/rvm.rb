# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  # Let users set the type of their rvm install.
  _cset(:rvm_type, :system)

  # Define rvm_path
  # This is used in the default_shell command to pass the required variable to rvm-shell, allowing
  # rvm to boostrap using the proper path. This is being lost in Capistrano due to the lack of a
  # full environment.
  _cset(:rvm_path) do
    case rvm_type
    when :root, :system
      "/usr/local/rvm"
    when :local, :user, :default
      "$HOME/.rvm/"
    else
      rvm_type.to_s.empty? ? "$HOME/.rvm" : rvm_type.to_s
    end
  end

  # Let users override the rvm_bin_path
  _cset(:rvm_bin_path) do
    case rvm_type
    when :root, :system
      "/usr/local/rvm/bin"
    when :local, :user, :default
      "$HOME/.rvm/bin"
    else
      rvm_type.to_s.empty? ? "#{rvm_path}/bin" : rvm_type.to_s
    end
  end

  # Use the default ruby on the server, by default :)
  _cset(:rvm_ruby_string, "default")

  # Set the rvm shell
  set :rvm_shell do
    shell = "exec #{File.join(fetch(:rvm_bin_path), "rvm-shell")}"
    ruby = fetch(:rvm_ruby_string).to_s.strip
    shell = "rvm_path=#{fetch :rvm_path} #{shell} '#{ruby}'" unless ruby.empty?
    shell
  end

  namespace :rvm do
    desc "[internal] Upload rvm wrapper"
    task :install_shell_wrapper do
      if exists?(:enable_rvm) && fetch(:enable_rvm) == true
        shell_contents = <<-EOS
  #!/bin/sh
  if test -d "#{fetch :rvm_path}"
  then
    #{fetch :rvm_shell} "$@"
  else
    exec bash "$@"
  fi
        EOS

        rvm_shell_wrapper_path = "/tmp/rvm_shell_wrapper.sh"

        put shell_contents, rvm_shell_wrapper_path, :mode => 0755

        set :default_shell, rvm_shell_wrapper_path
      end
    end

    desc "[internal] Remove rvm wrapper"
    task :remove_shell_wrapper do
      if exists?(:enable_rvm) && fetch(:enable_rvm) == true
        default_shell = fetch(:default_shell)
        set :default_shell, nil

        run <<-CMD
          rm -f #{default_shell}
        CMD
      end
    end
  end

  # Install the wrapper once the config has been parsed
  after "multistage:ensure", "rvm:install_shell_wrapper"

  # Remove the shell before exiting
  on :exit do
    find_and_execute_task "rvm:remove_shell_wrapper"
  end
end