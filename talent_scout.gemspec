$:.push File.expand_path("lib", __dir__)

require "talent_scout/version"

Gem::Specification.new do |s|
  s.name        = "talent_scout"
  s.version     = TalentScout::VERSION
  s.authors     = ["Jonathan Hefner"]
  s.email       = ["jonathan.hefner@gmail.com"]
  s.homepage    = "https://github.com/jonathanhefner/talent_scout"
  s.summary     = %q{Model-backed searches in Rails}
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.1"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "capybara", ">= 2.15", "< 4.0"
  s.add_development_dependency "yard", "~> 0.9"
end
