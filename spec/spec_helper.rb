require 'rubygems'
require 'rspec'

# Require the library (without receipts)
require File.expand_path("../../lib/capistrano-exts.rb", __FILE__)

# Define the path to the rendered templates
RENDERED_TEMPLATES_PATH = File.expand_path(File.join File.dirname(__FILE__), 'rendered_templates')

# Include all modules for easier tests
include Capistrano::Extensions
include Server

# Require support files
Dir[ROOT_PATH + "/spec/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  # config.mock_with :rspec
end