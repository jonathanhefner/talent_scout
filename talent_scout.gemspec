require_relative "lib/talent_scout/version"

Gem::Specification.new do |spec|
  spec.name        = "talent_scout"
  spec.version     = TalentScout::VERSION
  spec.authors     = ["Jonathan Hefner"]
  spec.email       = ["jonathan@hefner.pro"]
  spec.homepage    = "https://github.com/jonathanhefner/talent_scout"
  spec.summary     = %q{Model-backed searches in Rails}
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.metadata["source_code_uri"] + "/blob/master/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "rails", ">= 6.1"
end
