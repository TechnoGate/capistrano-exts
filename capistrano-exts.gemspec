# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "capistrano-exts/version"

Gem::Specification.new do |s|
  s.name        = "capistrano-exts"
  s.version     = Capistrano::Extensions::Version::STRING.dup
  s.authors     = ["Wael Nasreddine"]
  s.email       = ["wael.nasreddine@gmail.com"]
  s.homepage    = "https://github.com/TechnoGate/capistrano-exts"
  s.summary     = %q{Set of helper tasks to help with the initial server configuration and application provisioning.}
  s.description = <<-EOD
Capistrano exts is a set of helper tasks to help with the initial server
configuration and application provisioning. Things like creating the directory
structure, setting up that database, and other one-off you might find yourself
doing by hand far too often. It provides many helpful post-deployment tasks to
help you import/export database and contents as well as sync one stage with
another.
EOD

  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Run-time dependencies
  s.add_dependency 'capistrano'
  s.add_dependency 'capistrano_colors'
  s.add_dependency 'i18n'
  s.add_dependency 'activesupport', '~>3.2.3'

  # Development dependencies
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-bundler'
  s.add_development_dependency 'guard-rspec'

  # Development / Test dependencies
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
end
