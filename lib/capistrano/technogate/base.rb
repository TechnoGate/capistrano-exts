require 'capistrano'
require 'highline'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  # Taken from Stackoverflow
  # http://stackoverflow.com/questions/1661586/how-can-you-check-to-see-if-a-file-exists-on-the-remote-server-in-capistrano
  def remote_file_exists?(full_path)
    'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
  end

  def link_file(source_file, destination_file)
    if remote_file_exists?(source_file)
      run "#{try_sudo} ln -nsf #{source_file} #{destination_file}"
    end
  end

  def link_config_file(config_file, config_path = nil)
    config_path ||= "#{File.join release_path, 'config'}"
    link_file("#{File.join shared_path, 'config', config_file}", "#{File.join config_path, config_file}")
  end

  def blank?(var)
    !exists?(var) or var.nil? or var == false or var.empty?
  end

  def present?(var)
    !!!blank?(var)
  end

  def ask(what, options)
    default = options[:default]
    validate = options[:validate] || /(y(es)?)|(no?)|(a(bort)?|\n)/i
    echo = (options[:echo].nil?) ? true : options[:echo]

    ui = HighLine.new
    ui.ask("#{what}?  ") do |q|
      q.overwrite = false
      q.default = default
      q.validate = validate
      q.responses[:not_valid] = what
      unless echo
        q.echo = "*"
      end
    end
  end

  namespace :deploy do
    desc "Check if the branch is ready"
    task :check_if_branch_is_ready, :roles => :web do
      unless `git rev-parse #{branch}` == `git rev-parse origin/#{branch}`
        puts "ERROR: #{branch} is not the same as origin/#{branch}"
        puts "Run `git push` to sync changes."
        exit
      end
    end

    desc "Check if this revision has already been deployed."
    task :check_revision, :roles => :web do
      if remote_file_exists?("#{deploy_to}/current/REVISION")
        if `git rev-parse #{branch}`.strip == capture("cat #{deploy_to}/current/REVISION").strip
          response = ask("The verison you are trying to deploy is already deployed, should I continue (Yes, [No], Abort)", default: 'No')
          if response =~ /(no?)|(a(bort)?|\n)/i
            exit
          end
        end
      end
    end

    desc "Check if the remote is ready, should we run cap deploy:setup?"
    task :check_if_remote_ready, :roles => :web do
      unless remote_file_exists?("#{shared_path}")
        puts "ERROR: The project is not ready for deployment."
        puts "please run `cap deploy:setup"
        exit
      end
    end
  end

  # Dependencies
  before "deploy", "deploy:check_if_remote_ready"
  after "deploy:check_if_remote_ready", "deploy:check_if_branch_is_ready"
  after "deploy:check_if_branch_is_ready", "deploy:check_revision"
  after "deploy", "deploy:cleanup" # keeps only last 5 releases
end