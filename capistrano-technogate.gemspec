# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "capistrano-technogate/version"

Gem::Specification.new do |s|
  s.name        = "capistrano-technogate"
  s.version     = Capistrano::Technogate::Version::STRING.dup
  s.authors     = ["Wael Nasreddine"]
  s.email       = ["wael.nasreddine@gmail.com"]
  s.homepage    = "https://github.com/TechnoGate/capistrano-technogate"
  s.summary     = %q{This gem provides some receipts for helping me in my every-day development}
  s.description = s.summary

  s.rubyforge_project = "capistrano-technogate"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Run-time dependencies
  s.add_dependency('capistrano', '>=2.8.0')
  s.add_dependency('i18n', '>=0.6.0')
  s.add_dependency('activesupport', '>=3.1.0')

  # Development dependencies
  s.add_development_dependency('rspec', '>=2.6.0')
  s.add_development_dependency('mocha', '>=0.2.12')
  s.add_development_dependency('factory_girl', '>=2.0.5')
  s.add_development_dependency('faker19', '>=1.0.5')
  s.add_development_dependency('guard', '>=0.6.2')
  s.add_development_dependency('guard-bundler', '>=0.1.3')
  s.add_development_dependency('guard-rspec', '>=0.4.3')
  s.add_development_dependency('growl_notify', '0.0.1')
end