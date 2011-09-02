require 'capistrano'
require 'highline'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  on :load do
    if exists?(:capistrano_extensions_receipts)
      capistrano_extensions_receipts.each do |receipt|
        require "capistrano-extensions/receipts/#{receipt.to_s}"
      end
    end
  end
end