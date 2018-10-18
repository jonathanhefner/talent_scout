require "test_helper"
require "talent_scout"

class ModelSearchTest < Minitest::Test

  def test_kind_of_active_model
    assert_kind_of ActiveModel::Model, MyModelSearch.new
  end

  def test_attribute_assignment_type_casts_values
    search = MyModelSearch.new(CRITERIA_VALUES.transform_values(&:to_s))
    assert_equal CRITERIA_VALUES, search.attributes.symbolize_keys
  end

  def test_attribute_default_values
    search = MyModelSearch.new
    search.attributes.each do |name, value|
      assert_equal TalentScout::OrMissingType::MISSING, value
    end
  end

  def test_guess_model_class
    assert_equal MyModel, MyModelSearch.model
  end

  def test_results_with_full_criteria_values
    search = MyModelSearch.new(CRITERIA_VALUES)
    assert_results CRITERIA_VALUES, search
  end

  def test_results_with_missing_criteria_values
    group_regexp = /^(.+?)(?:_part\d)?$/
    groups = CRITERIA_VALUES.keys.group_by{|name| name.to_s[group_regexp, 1] }.values
    groups.each do |group|
      group.each do |name|
        search = MyModelSearch.new(CRITERIA_VALUES.except(name))
        assert_results CRITERIA_VALUES.except(*group), search
      end
    end
  end

  private

  class MyModel
    def self.all
      MockRelation.new
    end

    class MockRelation
      attr_reader :to_a

      def initialize(to_a = [])
        @to_a = to_a
      end

      def append(name, value)
        self.class.new(@to_a + [[name, value, :OK]])
      end
    end
  end

  class MyModelSearch < TalentScout::ModelSearch
    criteria :str1 do |x|
      append(:str1, x)
    end

    criteria :int1, :integer do |x|
      append(:int1, x)
    end

    criteria %i[date1_part1 date1_part2], :date do |x, y|
      append(:date1_part1, x).append(:date1_part2, y)
    end

    criteria :choice1, { "foo" => :foo, "bar" => :bar } do |x|
      append(:choice1, x)
    end
  end

  CRITERIA_VALUES = {
    str1: "abc",
    int1: 123,
    date1_part1: Date.new(1999, 12, 31),
    date1_part2: Date.new(2000, 01, 01),
    choice1: :foo,
  }

  def assert_results(criteria_values, search)
    assert_equal criteria_values.map{|k, v| [k, v, :OK] }, search.results.to_a
  end

end
