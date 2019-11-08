require "test_helper"
require "generators/talent_scout/search/search_generator"

class SearchGeneratorTest < Rails::Generators::TestCase
  tests TalentScout::Generators::SearchGenerator
  destination File.join(__dir__, "tmp")
  setup :prepare_destination

  def test_creates_necessary_files
    ["person", "namespaced/person"].each do |resource|
      run_generator([resource, "--test-framework=test_unit"])
      assert_file "app/searches/#{resource}_search.rb", /#{resource.classify}Search/
      assert_file "test/searches/#{resource}_search_test.rb", /#{resource.classify}SearchTest/
    end
  end

end
