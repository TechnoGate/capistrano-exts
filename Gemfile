source "http://rubygems.org"

group :development, :test do
  gem 'cuken', path: '/Users/wael/Projects/Playground/cuken'
end

# Specify your gem's dependencies in capistrano-exts.gemspec
gemspec

platforms :ruby do
  # Require rbconfig to figure out the target OS
  require 'rbconfig'

  unless ENV['TRAVIS']
    if RbConfig::CONFIG['target_os'] =~ /darwin/i
      gem 'rb-fsevent', require: false
      gem 'ruby-growl', require: false
      gem 'growl', require: false
    end
    if RbConfig::CONFIG['target_os'] =~ /linux/i
      gem 'rb-inotify', require: false
      gem 'libnotify', require: false
    end
  end
end
