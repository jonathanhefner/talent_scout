require "test_helper"
require "talent_scout"

class ModelSearchTest < Minitest::Test

  def test_kind_of_active_model
    assert_kind_of ActiveModel::Model, MyModelSearch.new
  end

  def test_constructor_with_unsafe_controller_params
    params = ActionController::Parameters.new(CRITERIA_VALUES)
    refute params.permitted? # sanity check
    search = MyModelSearch.new(params) # should not raise
    assert_equal CRITERIA_VALUES, search.attributes.symbolize_keys
  end

  def test_constructor_with_invalid_controller_params
    params = ActionController::Parameters.new(CRITERIA_VALUES.merge(bad: "BAD"))
    search = MyModelSearch.new(params) # should not raise
    refute_includes search.attributes.symbolize_keys, :bad
  end

  def test_constructor_ignores_blank_controller_params
    params = ActionController::Parameters.new(CRITERIA_VALUES.transform_values{ "" })
    search = MyModelSearch.new(params)
    assert_equal MyModelSearch.new.attributes, search.attributes
  end

  def test_attribute_assignment_type_casts_values
    search = MyModelSearch.new(CRITERIA_VALUES.transform_values(&:to_s))
    assert_equal CRITERIA_VALUES, search.attributes.symbolize_keys
  end

  def test_attribute_default_values
    search = MyModelSearch.new
    search.attributes.each do |name, value|
      expected = CRITERIA_DEFAULT_VALUES.fetch(name.to_sym,
        TalentScout::ModelSearch::MISSING_VALUE)
      assert_equal expected, value
    end
  end

  def test_guess_model_class
    assert_equal MyModel, MyModelSearch.model
  end

  def test_override_model_class
    assert_equal MyModel, MyOtherModelSearch.model
  end

  def test_results_with_full_criteria_values
    search = MyModelSearch.new(CRITERIA_VALUES)
    assert_results CRITERIA_VALUES, search.results
  end

  def test_results_with_missing_criteria_values
    group_regexp = /^(.+?)(?:_part\d)?$/
    groups = CRITERIA_VALUES.keys.group_by{|name| name.to_s[group_regexp, 1] }.values
    groups.each do |group|
      group.each do |name|
        search = MyModelSearch.new(CRITERIA_VALUES.except(name))
        expected_values = if group.none?{|n| CRITERIA_DEFAULT_VALUES.key?(n) }
          CRITERIA_VALUES.except(*group)
        else
          CRITERIA_DEFAULT_VALUES.merge(CRITERIA_VALUES.except(name))
        end
        assert_results expected_values, search.results
      end
    end
  end

  def test_results_with_base_scope
    base_params = { base_str1: "hello", base_str2: "world" }
    base_scope = MyModel.all.where(base_params)
    search = MyModelSearch.new(CRITERIA_VALUES)
    assert_results base_params.merge(CRITERIA_VALUES), search.results(base_scope)
  end

  def test_results_skips_conditional_criteria_block
    search = MyModelSearch.new(CRITERIA_VALUES.merge(skip_if_neg: -1))
    assert_results CRITERIA_VALUES.except(:skip_if_neg), search.results
  end

  def test_results_skips_void_type_criteria
    search = MyModelSearch.new(CRITERIA_VALUES.merge(skip_if_false: false))
    assert_results CRITERIA_VALUES.except(:skip_if_false), search.results
  end

  def test_modify_via_with
    search1 = MyModelSearch.new
    search2 = search1.with(CRITERIA_VALUES)
    refute_equal search1.results, search2.results
    assert_results CRITERIA_VALUES, search2.results
  end

  private

  CRITERIA_DEFAULT_VALUES = {
    str2: "abcdefault",
    date2_part1: Date.new(1970, 01, 01),
    date2_part2: Date.new(1970, 01, 01),
  }

  CRITERIA_VALUES = {
    str1: "abc",
    str2: "def",
    int1_part1: 123,
    int1_part2: 456,
    date1_part1: Date.new(1999, 12, 31),
    date1_part2: Date.new(2000, 01, 01),
    date2_part1: Date.new(2012, 12, 21),
    date2_part2: Date.new(2012, 12, 22),
    choice1_part1: :foo,
    choice1_part2: :bar,
    choice2: 99,
    skip_if_neg: 1,
    skip_if_false: true,
  }

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

    criteria :str2, default: CRITERIA_DEFAULT_VALUES[:str2] do |x|
      append(:str2, x)
    end

    criteria %i[int1_part1 int1_part2], :integer do |x, y|
      append(:int1_part1, x).append(:int1_part2, y)
    end

    criteria %i[date1_part1 date1_part2], :date, &:date1

    criteria %i[date2_part1 date2_part2], :date,
      default: CRITERIA_DEFAULT_VALUES[:date2_part1]

    criteria %i[choice1_part1 choice1_part2], { "foo" => :foo, "bar" => :bar }

    criteria :choice2, [1, 2, 99, 100] do |x|
      append(:choice2, x)
    end

    criteria :skip_if_neg, :integer do |x|
      append(:skip_if_neg, x) unless x < 0
    end

    criteria :skip_if_false, :void do
      append(:skip_if_false, true)
    end
  end

  class MyOtherModelSearch < TalentScout::ModelSearch
    model MyModel
  end

  def assert_results(criteria_values, results)
    expected = criteria_values.map{|k, v| [k, v, :OK] }.sort_by(&:first)
    actual = results.to_a.sort_by(&:first)
    assert_equal expected, actual
  end

end
