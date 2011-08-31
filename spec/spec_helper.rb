require 'rubygems'
require 'faker'
require 'rspec'

# Require the library (without receipts)
require File.expand_path("../../lib/capistrano-technogate.rb", __FILE__)
include Capistrano::TechnoGate

# Require factories
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