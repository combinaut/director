$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "director/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "director"
  s.version     = Director::VERSION
  s.authors     = ["Ryan Wallace", "Nicholas Jakobsen"]
  s.email       = ["contact@culturecode.ca"]
  s.homepage    = "http://github.com/culturecode/director"
  s.summary     = "Rack Middleware that handles directs incoming requests to their aliased path targets"
  s.description = "Rack Middleware that handles directs incoming requests to their aliased path targets"

  s.files = Dir["{app}/**/*"] + Dir["{lib}/**/*"] + ["MIT-LICENSE", "README.md"]

  s.add_dependency "rails", ">= 4.2"
  s.add_development_dependency 'combustion', '~> 0.7.0'
  s.add_development_dependency 'rspec-rails', '~> 3.6'
  s.add_development_dependency 'sqlite3'
end
