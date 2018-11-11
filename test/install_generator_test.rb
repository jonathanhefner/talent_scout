require "test_helper"
require "generators/talent_scout/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests TalentScout::Generators::InstallGenerator
  destination File.join(__dir__, "tmp")
  setup :prepare_destination

  def test_necessary_files_are_created
    run_generator

    assert_file "config/locales/talent_scout.en.yml"
  end

end
