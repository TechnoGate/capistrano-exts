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
  s.add_dependency('capistrano', '~>2.8.0')
  s.add_dependency('i18n', '~>0.6.0')
  s.add_dependency('activesupport', '~>3.1.0')

  # Development dependencies
  s.add_development_dependency('guard', '~>0.6.2')
  s.add_development_dependency('guard-bundler', '~>0.1.3')
  s.add_development_dependency('guard-rspec', '~>0.4.3')

  # Development / Test dependencies
  s.add_development_dependency('rspec', '~>2.6.0')
  # s.add_development_dependency('mocha', '~>0.2.12')
  # s.add_development_dependency('factory_girl', '~>2.0.5')
  # s.add_development_dependency('faker19', '~>1.0.5')
end