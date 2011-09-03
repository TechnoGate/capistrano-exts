# DEVELOPMENT-specific deployment configuration
# please put general deployment config in config/deploy.rb

# Here you can set the server which you would like to, each server
# each role can have multiple servers, each server defined as user@server.com:port
# => port can be omiped and it defaults to 22
role :web, 'root@example_dev_web.com:22'
role :app, 'root@example_dev_app.com:22'
role :db, 'root@example_dev_db.com:22', primary: true

# The project's branch to use
# Uncomment and edit this if you're using git, for other SCM's please refer
# to capistrano's documentation
set :branch, "master"

# Use sudo ?
set :use_sudo, false

# Define deployments options
set :deploy_to,   "/home/vhosts/#{application}"
set :deploy_via,  :remote_cache
set :logs_path,   "#{deploy_to}/logs"
set :public_path, -> { "#{current_path}/public" }

# Keep only the last 5 releases
set :keep_releases, 5

# Using RVM? Set this to the ruby version/gemset to use
set :rvm_ruby_string, "1.9.2"

# Mysql credentials
set :mysql_credentials_file,                  -> { "#{deploy_to}/.mysql_password"}
set :mysql_credentials_host_regex,            /hostname: (.*)$/o
set :mysql_credentials_host_regex_match,      1
set :mysql_credentials_user_regex,            /username: (.*)$/o
set :mysql_credentials_user_regex_match,      1
set :mysql_credentials_pass_regex,            /password: (.*)$/o
set :mysql_credentials_pass_regex_match,      1
set :mysql_root_credentials_file,             "/root/.mysql_password"
set :mysql_root_credentials_host_regex,       /hostname: (.*)$/o
set :mysql_root_credentials_host_regex_match, 1
set :mysql_root_credentials_user_regex,       /username: (.*)$/o
set :mysql_root_credentials_user_regex_match, 1
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

# HTTP Basic Authentifications
# Uncomment this if you would like to add HTTP Basic authentifications,
#
# Change the 'web_server_auth_file' to the absolute path of the htpasswd file
# web_server_auth_credentials is an array of user/password hashes, you can use
# gen_pass(length) in a Proc to generate a new password as shown below
#
set :web_server_auth_file,        -> { "/etc/nginx/htpasswds/#{fetch :application}.crypt" }
set :web_server_auth_credentials, [
                                    {user: 'user1', password: 'pass1'},
                                    {user: 'user2', password: -> { gen_pass(8) } },
                                  ]

# Enable mode rewrite ?
set :web_server_mod_rewrite, true

# Which server mode to operate on?
# Valid options:
#
# For Nginx:
# => :rails_reverse_proxy, :passenger, :php_fpm
# => :rails_reverse_proxy is used for unicorn (Rack apps)
# => :passenger runs rails apps
# => :php_fpm is used to deliver websites written using PHP
#
# For Apache
# =>
set :web_server_mode, :php_fpm

# Server mode specific configurations
# Uncomment and edit the one depending on the enabled mode
# php_fpm settings
# => On which host, php-fpm is running ?
set :php_fpm_host, 'localhost'
# => Which port ?
set :php_fpm_port, '9000'

# reverse_proxy settings (Unicorn for example)
# => On which host the proxy is running ?
# set :reverse_proxy_server_address, 'localhost'
# => On which port ?
# set :reverse_proxy_server_port, 45410
# => What is the path to the socket file
# set :reverse_proxy_socket, -> { "#{shared_path}/sockets/unicorn.sock"}

#
#############