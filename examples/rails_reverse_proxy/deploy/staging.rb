# DEVELOPMENT-specific deployment configuration
# please put general deployment config in config/deploy.rb

# Here you can set the server which you would like to, each server
# each role can have multiple servers, each server defined as user@server.com:port
# => port can be omiped and it defaults to 22
role :web, 'root@example_staging_web.com:22'
role :app, 'root@example_staging_app.com:22'
role :db, 'root@example_staging_db.com:22', primary: true

# Permissions and ownership
# Uncomment if necessary...
# set :app_owner, 'www-data'
# set :app_group, 'www-data'
# set :group_writable, true

# The project's branch to use
# Uncomment and edit this if you're using git, for other SCM's please refer
# to capistrano's documentation
set :branch, "staging"

# Use sudo ?
set :use_sudo, false

# Define deployments options
set :deploy_to,   -> { "/home/vhosts/#{fetch :stage}/#{fetch :application}" }
set :logs_path,   -> { "#{fetch :deploy_to}/logs" }
set :public_path, -> { "#{fetch :current_path}/public" }
set :backup_path, -> { "#{fetch :deploy_to}/backups" }

# How should we deploy?
# Valid options:
# => checkout: this deployment strategy does an SCM checkout on each target
#              host. This is the default deployment strategy for Capistrano.
#
# => copy: this deployment strategy work by preparing the source code locally,
#          compressing it, copying the file to each target host, and
#          uncompressing it to the deployment directory.
#          NOTE: This strategy has more options you can configure, please refer
#                to capistrano/recipes/deploy/strategy/copy.rb (in capistrano)
#                source or documentation for more information
#
# => export: this deployment strategy does an SCM export on each target host.
#
# => remote_cache: this deployment strategy keeps a cached checkout of the
#                  source code on each remote server. Each deploy simply updates
#                  the cached checkout, and then does a copy from the cached
#                  copy to the final deployment location.
set :deploy_via,  :remote_cache

# Keep only the last 5 releases
set :keep_releases, 5

# Using RVM? Set this to the ruby version/gemset to use
set :rvm_ruby_string, "1.9.3"

#############
# Contents
#

# Here you can set all the contents folders, a content folder is a shared folder
# public or private but the contents are shared between all releases.
# The contents_folders is a hash of key/value where the key is the name of the folder
# created under 'shared_path/contents' and symlinked to the value (absolute path)
# you can use public_path/current_path/deploy_to etc...
# set :contents_folder, {
#   'image' => "#{fetch :public_path}/images",
#   'video' => "#{fetch :public_path}/videos",
# }

# Here you can define which files/folder you would like to keep, these files
# and folders are not considered contents so they will not be synced from one
# server to another with the tasks mulltistage:sync:* instead they will be kept
# between versions in the shared/items folder
# set :shared_items, [
#   'public/.htaccess',
#   'public/sitemap.xml',
#   'public/robots.txt',
# ]

# Link config files
set :configuration_files, ['database.yml']

#
#
#############

#############
# Mysql
#

# Where is located the primary database folder?
set :mysql_db_server,                         'localhost'

# What is the database name for this project/stage ?
set :mysql_db_name,                           -> { "#{fetch :application}_#{fetch :stage}" }

# What is the database user ?
set :mysql_db_user,                           -> { "#{fetch :application}" }

# Where the database credentials are stored on the server ?
set :mysql_credentials_file,                  -> { "#{deploy_to}/.mysql_password"}

# Define the regex / match that will be ran against the contents of the file above to fetch the hostname
set :mysql_credentials_host_regex,            /hostname: (.*)$/o
set :mysql_credentials_host_regex_match,      1

# Define the regex / match that will be ran against the contents of the file above to fetch the username
set :mysql_credentials_user_regex,            /username: (.*)$/o
set :mysql_credentials_user_regex_match,      1

# Define the regex / match that will be ran against the contents of the file above to fetch the password
set :mysql_credentials_pass_regex,            /password: (.*)$/o
set :mysql_credentials_pass_regex_match,      1

# Where can we find root credentials ?
# NOTE: These options are only used if you run deploy:server:setup which calls mysql:create_db_user
set :mysql_root_credentials_file,             "/root/.mysql_password"

# Define the regex / match that will be ran against the contents of the file above to fetch the hostname
set :mysql_root_credentials_host_regex,       /hostname: (.*)$/o
set :mysql_root_credentials_host_regex_match, 1

# Define the regex / match that will be ran against the contents of the file above to fetch the username
set :mysql_root_credentials_user_regex,       /username: (.*)$/o
set :mysql_root_credentials_user_regex_match, 1

# Define the regex / match that will be ran against the contents of the file above to fetch the password
set :mysql_root_credentials_pass_regex,       /password: (.*)$/o
set :mysql_root_credentials_pass_regex_match, 1

#############
# Web server
#

# Which web server to use?
# valid options: :nginx and :apache
set :web_server_app, :nginx

# Server specific configurations
# Uncomment as necessary, default option are as follow
# set :nginx_init_path, '/etc/init.d/nginx'
# set :apache_init_path, '/etc/init.d/apache2'

# Absolute path to this application's web server configuration
# This gem suppose that you are already including files from the folder you're placing
# the config file in, if not the application won't be up after deployment
set :web_conf_file, -> { "/etc/nginx/#{fetch(:stage).to_s}/#{fetch :application}.conf" }

# Which port does the server runs on ?
set :web_server_listen_port, 80

# What is the application url ?
# THis is used for Virtual Hosts
set :application_url, %w(example.com www.example.com)

# What are the names of the indexes
set :web_server_indexes, %w(index.php index.html)

# Deny access ?
# Define here an array of files/pathes to deny access from.
set :denied_access, [ ".htaccess" ]

# HTTP Basic Authentifications
# Uncomment this if you would like to add HTTP Basic authentifications,
#
# Change the 'web_server_auth_file' to the absolute path of the htpasswd file
# web_server_auth_credentials is an array of user/password hashes, you can use
# gen_pass(length) in a Proc to generate a new password as shown below
#
# set :web_server_auth_file,        -> { "/etc/nginx/htpasswds/#{fetch :application}.crypt" }
# set :web_server_auth_credentials, [
#                                     {user: 'user1', password: 'pass1'},
#                                     {user: 'user2', password: -> { gen_pass(8) } },
#                                   ]

# Enable mode rewrite ?
set :web_server_mod_rewrite, true

# Which server mode to operate on?
# Valid options:
#
# For Nginx:
# => :reverse_proxy, :passenger, :php_fpm
# => :reverse_proxy is used for unicorn (Rack apps)
# => :passenger runs rails apps
# => :php_fpm is used to deliver websites written using PHP
#
# For Apache
# =>
set :web_server_mode, :reverse_proxy

# Server mode specific configurations
# Uncomment and edit the one depending on the enabled mode
# php_fpm settings
# => On which host, php-fpm is running ?
# set :php_fpm_host, 'localhost'
# => Which port ?
# set :php_fpm_port, '9000'

# reverse_proxy settings (Unicorn for example)
# => On which host the proxy is running ?
# set :reverse_proxy_server_address, 'localhost'
# => On which port ?
# set :reverse_proxy_server_port, 45410
# => What is the path to the socket file
set :reverse_proxy_socket, -> { "#{shared_path}/sockets/unicorn.sock"}

#
#
#############

#############
# Contao
#

# Where do you store contao contents ?
# The contents are stored in the shared path because they are uploaded from
# contao's admin section
# set :contents_path, -> { "#{fetch :public_path}/tl_files/contents"}

#
#
#############