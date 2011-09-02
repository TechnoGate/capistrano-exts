# encoding: utf-8

# Require active_support core extensions
require 'active_support/core_ext'

# Active Support's core_ext define capture, remove it in favor of capistrano's capture function
alias :__capture__ :capture
undef :capture

Dir["#{File.dirname(__FILE__)}/core_ext/**/*.rb"].each { |f| require f }