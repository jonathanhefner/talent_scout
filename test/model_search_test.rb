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
        self.class.new(@to_a + [[name.to_sym, value, :OK]])
      end

      def where(args)
        args.reduce(self) do |rel, (name, value)|
          rel.append(name, value)
        end
      end

      def date1(x, y)
        append(:date1_part1, x).append(:date1_part2, y)
      end
    end
  end

  class MyModelSearch < TalentScout::ModelSearch
    criteria :str1 do |x|
      append(:str1, x)
    end

    criteria %i[int1_part1 int1_part2], :integer do |x, y|
      append(:int1_part1, x).append(:int1_part2, y)
    end

    criteria %i[date1_part1 date1_part2], :date, &:date1

    criteria %i[choice1_part1 choice1_part2], { "foo" => :foo, "bar" => :bar }
  end

  CRITERIA_VALUES = {
    str1: "abc",
    int1_part1: 123,
    int1_part2: 456,
    date1_part1: Date.new(1999, 12, 31),
    date1_part2: Date.new(2000, 01, 01),
    choice1_part1: :foo,
    choice1_part2: :bar,
  }

  def assert_results(criteria_values, search)
    assert_equal criteria_values.map{|k, v| [k, v, :OK] }, search.results.to_a
  end

end
