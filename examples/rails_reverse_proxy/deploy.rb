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
set :capistrano_extensions, [:multistage, :git, :base, :mysql, :rails, :servers]

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

##################
## DEPENDENCIES ##
##################

after "deploy", "deploy:cleanup" # keeps only last 5 releases

###########################
## DO NOT TOUCH AFTER ME ##
###########################

# Require capistrano-exts
require 'capistrano-exts'

# rvm bootstrap
# Comment this if ruby is not installed on the server!
# require "rvm/capistrano"