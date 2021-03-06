require 'capistrano-exts/receipts/mysql'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  # Prevent capistrano from creating log, system and pids folders.
  set :shared_children, Array.new

  namespace :deploy do
    desc "Empty task, overriden by #{__FILE__}"
    task :finalize_update do
      # Empty task, we do not want to delete the system folder.
    end
  end

  namespace :contao do
    desc "[internal] Setup contao"
    task :setup, :roles => :app, :except => { :no_release => true } do
      # Empty task, the rest should hook to it
    end

    desc "[internal] Setup contao shared contents"
    task :setup_shared_folder, :roles => :app, :except => { :no_release => true } do
      shared_path = fetch :shared_path
      run <<-CMD
        #{try_sudo} mkdir -p #{shared_path}/logs &&
        #{try_sudo} mkdir -p #{shared_path}/config
      CMD

      # TODO: The deny access should follow denied_access config
      deny_htaccess = "order deny,allow\n"
      deny_htaccess << "deny from all"

      put deny_htaccess, "#{shared_path}/logs/.htaccess"
    end

    desc "[internal] Setup contao's localconfig"
    task :setup_localconfig, :roles => :app, :except => { :no_release => true } do
      localconfig_php_config_path = "#{fetch :shared_path}/config/public_system_config_localconfig.php"
      on_rollback { run "rm -f #{localconfig_php_config_path}" }

      localconfig = File.read("config/examples/localconfig.php.erb")
      mysql_credentials = fetch :mysql_credentials

      mysql_host = mysql_credentials[:host]
      mysql_user = mysql_credentials[:user]
      mysql_password = mysql_credentials[:pass]
      mysql_database = fetch :mysql_db_name
      contao_env = :production

      put ERB.new(localconfig).result(binding), localconfig_php_config_path
    end

    desc "[internal] Link files from contao to inside public folder"
    task :link_contao_files, :roles => :app, :except => { :no_release => true } do
      files = exhaustive_list_of_files_to_link("#{fetch :latest_release}/contao", "#{fetch :latest_release}/public")
      commands = files.map do |list|
        "#{try_sudo} ln -nsf #{list[0]} #{list[1]}"
      end

      begin
        run commands.join(';')
      rescue Capistrano::CommandError
        abort "Unable to create to link contao files"
      end
    end

    desc "[internal] Fix contao's symlinks to the shared path"
    task :fix_links, :roles => :app, :except => { :no_release => true } do
      latest_release = fetch :latest_release
      shared_path = fetch :shared_path

      # Remove files
      run <<-CMD
        #{try_sudo} rm -rf #{latest_release}/public/system/logs
      CMD

      # Create symlinks
      run <<-CMD
        #{try_sudo} ln -nsf #{shared_path}/logs #{latest_release}/public/system/logs
      CMD
    end

    desc "Upload contao assets"
    task :upload_assets, :roles => :app, :except => { :no_release => true } do
      upload("public/resources", "#{fetch :latest_release}/public/resources", :via => :scp, :recursive => true)
    end

    desc "[internal] Generate production assets"
    task :generate_production_assets, :roles => :app, :except => { :no_release => true } do
      run_locally "bundle exec rake CONTAO_ENV=production assets:precompile"
    end

    desc "[internal] Generate development assets"
    task :generate_development_assets, :roles => :app, :except => { :no_release => true } do
      run_locally "bundle exec rake assets:precompile"
    end
  end

  # Dependencies
  after "deploy:setup", "contao:setup"
  after "contao:setup", "contao:setup_shared_folder"
  after "contao:setup", "contao:setup_localconfig"
  after "deploy:finalize_update", "contao:link_contao_files"
  after "contao:link_contao_files", "contao:fix_links"

  # Assets
  after "contao:link_contao_files", "contao:upload_assets"
  before "contao:upload_assets", "contao:generate_production_assets"
  after  "contao:upload_assets", "contao:generate_development_assets"

  # Mysql Credentials
  before "contao:setup_localconfig", "mysql:credentials"
  before "contao:setup_db", "mysql:credentials"
end
