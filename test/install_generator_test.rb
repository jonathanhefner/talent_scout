require "test_helper"
require "generators/talent_scout/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests TalentScout::Generators::InstallGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  test "creates necessary files" do
    run_generator

    assert_file "config/locales/talent_scout.en.yml"
  end

end
