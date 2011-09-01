# encoding: utf-8

# Add it to PATH
ROOT_PATH = File.expand_path(File.dirname(__FILE__))
$:.unshift(ROOT_PATH) if File.directory?(ROOT_PATH) && !$:.include?(ROOT_PATH)

# Require active_support core extensions
require 'active_support/core_ext'

# Require our core extensions
require 'capistrano-technogate/core_ext'

# Require all servers
Dir["#{ROOT_PATH}/capistrano-technogate/servers/**/*.rb"].each { |f| require f }