# encoding: utf-8

# Add it to PATH
ROOT_PATH = File.expand_path(File.dirname(__FILE__))
$: << ROOT_PATH if File.directory?(ROOT_PATH) and not $:.include?(ROOT_PATH)

# Require our core extensions
require 'capistrano-exts/core_ext'

# require Capistrano colors
require 'capistrano/logger'
require 'capistrano_colors/logger'

# Printed credentials
Capistrano::Logger.add_color_matcher({ :match => /adapter:|hostname:|username:|password:/, :color => :red, :level => Capistrano::Logger::TRACE, :prio => -20, :attribute => :blink })

# Warnings
Capistrano::Logger.add_color_matcher({ :match => /WARNING:/, :color => :yellow, :level => Capistrano::Logger::INFO, :prio => -20 })

# Errors
Capistrano::Logger.add_color_matcher({ :match => /ERROR:/, :color => :red, :level => Capistrano::Logger::IMPORTANT, :prio => -20 })

# Require requested receipts
require 'capistrano-exts/receipts' if defined?(Capistrano::Configuration)

# Require all servers
Dir["#{ROOT_PATH}/capistrano-exts/servers/*.rb"].each { |f| require f }