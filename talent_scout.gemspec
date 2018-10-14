$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "talent_scout/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "talent_scout"
  s.version     = TalentScout::VERSION
  s.authors     = [""]
  s.email       = [""]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of TalentScout."
  s.description = "TODO: Description of TalentScout."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.1"

  s.add_development_dependency "sqlite3"
end
