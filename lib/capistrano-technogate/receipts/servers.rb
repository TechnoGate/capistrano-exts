# encoding: utf-8

# Requirements
require 'capistrano'
require 'capistrano-technogate/receipts/base'
require 'capistrano-technogate/receipts/mysql'

Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :server do
    task :create_host do

    end
  end
end