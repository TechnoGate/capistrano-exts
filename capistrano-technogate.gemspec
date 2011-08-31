# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "capistrano/technogate/version"

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

  s.add_dependency('capistrano', '>=1.0.0')
end
