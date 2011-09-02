# encoding: utf-8

# Add it to PATH
ROOT_PATH = File.expand_path(File.dirname(__FILE__))
$: << ROOT_PATH if File.directory?(ROOT_PATH) and not $:.include?(ROOT_PATH)

# Require our core extensions
require 'capistrano-exts/core_ext'

# Require requested receipts
require 'capistrano-exts/receipts' if defined?(Capistrano::Configuration)

# Require all servers
Dir["#{ROOT_PATH}/capistrano-exts/servers/*.rb"].each { |f| require f }