# Adding necessary paths
$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.

#####################
## CHANGE AFTER ME ##
#####################

set :application,           "example_app"
set :repository,            "git://github.com/example/example_app.git"
set :scm,                   :git
set :git_enable_submodules, 1

# Stages
set :stages, [:development, :staging, :production]
set :default_stage, :development

# Capistrano extensions
set :capistrano_extensions, [:multistage, :git, :deploy, :mysql, :contao, :servers]

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

# Bundler
# set :bundle_gemfile, "Gemfile"
# set :bundle_dir, File.join(fetch(:shared_path), 'bundle')
# set :bundle_flags, "--deployment --quiet"
# set :bundle_without, [:development, :test]
# set :bundle_cmd, "bundle" # e.g. "/opt/ruby/bin/bundle"
# set :bundle_roles, [:app]

##################
## DEPENDENCIES ##
##################

after "deploy", "deploy:cleanup" # keeps only last 5 releases

##################
## REQUIREMENTS ##
##################

# Require capistrano-exts
require 'capistrano-exts'

# Require bundler tasks
# require 'bundler/capistrano'