require 'capistrano'
require 'capistrano/errors'
require 'erb'


# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

DEFAULT_RECEIPTS = %w{functions deploy web files}

Capistrano::Configuration.instance(:must_exist).load do
  on :load do
    if exists?(:capistrano_extensions)
      # Merge the requested receipts with the default receipts
      capistrano_extensions = fetch(:capistrano_extensions) << DEFAULT_RECEIPTS
      capistrano_extensions.flatten!.uniq!

      # Require requested + default receipts
      capistrano_extensions.each do |receipt|
        require "capistrano-exts/receipts/#{receipt.to_s}"
      end
    end
  end
end