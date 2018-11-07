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

  def test_constructor_raises_on_invalid_criteria_name
    assert_raises ActiveModel::UnknownAttributeError do
      MyModelSearch.new(bad: "BAD")
    end
  end

  def test_attribute_assignment_type_casts_values
    search = MyModelSearch.new(CRITERIA_VALUES.transform_values(&:to_s))
    assert_equal CRITERIA_VALUES, search.attributes.symbolize_keys
  end

  def test_attribute_assignment_type_casts_multiparameter_values
    multiparameter = CRITERIA_VALUES.flat_map do |name, value|
      case value
      when Date
        %i[year month day].each_with_index.
          map{|part, i| ["#{name}(#{i + 1})", value.send(part).to_s] }
      when DateTime, Time
        %i[year month day hour min sec].each_with_index.
          map{|part, i| ["#{name}(#{i + 1})", value.send(part).to_s] }
      else
        [[name, value]]
      end
    end.to_h

    search = MyModelSearch.new(multiparameter)
    assert_equal CRITERIA_VALUES, search.attributes.symbolize_keys
  end

  def test_attribute_value_before_type_cast_readers
    before_type_cast = CRITERIA_VALUES.transform_values(&:to_s)
    search = MyModelSearch.new(before_type_cast)
    before_type_cast.each do |name, value|
      assert_equal value, search.send("#{name}_before_type_cast")
    end
  end

  def test_attribute_default_values
    search = MyModelSearch.new
    assert_equal CRITERIA_DEFAULT_VALUES, search.attributes.symbolize_keys.compact
  end

  def test_guess_model_class
    assert_equal MyModel, MyModelSearch.model
  end

  def test_override_model_class
    assert_equal MyModel, MyOtherModelSearch.model
  end

  def test_inherits_model_class
    assert_equal MyModel, MyInheritingSearch.model
  end

  def test_results_with_full_criteria_values
    search = MyModelSearch.new(CRITERIA_VALUES)
    assert_results CRITERIA_VALUES, search.results
  end

  def test_inherits_criteria
    criteria_values = CRITERIA_VALUES.merge(new_str1: "new")
    search = MyInheritingSearch.new(criteria_values)
    assert_results criteria_values, search.results
  end

  def test_results_with_missing_criteria_values
    CRITERIA_VALUES.keys.each do |name|
      search = MyModelSearch.new(CRITERIA_VALUES.except(name))
      expected_values = CRITERIA_DEFAULT_VALUES.key?(name) ?
        CRITERIA_VALUES.merge(name => CRITERIA_DEFAULT_VALUES[name]) :
        CRITERIA_VALUES.except(*CRITERIA_GROUPINGS[name])
      assert_results expected_values, search.results
    end
  end

  def test_results_with_explicit_nil_criteria_values
    nilable = CRITERIA_VALUES.keys.grep(/^(?:str|date)\d/)
    refute_empty nilable # sanity check
    nilable.each do |name|
      criteria_values = CRITERIA_VALUES.merge(name => nil)
      search = MyModelSearch.new(criteria_values)
      assert_results criteria_values, search.results
    end
  end

  def test_results_with_invalid_criteria_values
    fallible = CRITERIA_VALUES.keys.grep(/^(?:date|choice)\d/)
    refute_empty fallible # sanity check
    fallible.each do |name|
      search = MyModelSearch.new(CRITERIA_VALUES.merge(name => "BAD"))
      expected_values = CRITERIA_VALUES.except(*CRITERIA_GROUPINGS[name])
      assert_results expected_values, search.results
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

  def test_modify_via_with_raises_on_invalid_criteria_name
    search = MyModelSearch.new
    assert_raises ActiveModel::UnknownAttributeError do
      search.with(bad: "BAD")
    end
  end

  def test_modify_via_without
    search1 = MyModelSearch.new(CRITERIA_VALUES)
    search2 = search1.without(*CRITERIA_DEFAULT_VALUES.keys)
    refute_equal search1.results, search2.results
    assert_results CRITERIA_VALUES.merge(CRITERIA_DEFAULT_VALUES), search2.results
  end

  def test_modify_via_without_raises_on_invalid_criteria_name
    search = MyModelSearch.new(CRITERIA_VALUES)
    assert_raises ActiveModel::UnknownAttributeError do
      search.without(:bad)
    end
  end

  def test_choices_for
    search = MyModelSearch.new
    CRITERIA_CHOICES.each do |name, choices|
      assert_equal choices.keys, search.choices_for(name.to_sym)
      assert_equal choices.keys, search.choices_for(name.to_s)
    end
  end

  def test_choices_for_raises_on_invalid_criteria_name
    search = MyModelSearch.new
    (CRITERIA_VALUES.keys - CRITERIA_CHOICES.keys + [:bad]).each do |name|
      assert_raises(ArgumentError){ search.choices_for(name) }
    end
  end

  private

  CRITERIA_CHOICES = {
    choice1_part1: { "foo" => :foo, "bar" => :bar },
    choice1_part2: { "foo" => :foo, "bar" => :bar },
    choice2: { "1" => 1, "2" => 2, "99" => 99, "100" => 100 },
  }

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
    datetime1: DateTime.new(2038, 01, 19, 03, 14, 07, 0000).utc,
    choice1_part1: :foo,
    choice1_part2: :bar,
    choice2: 99,
    skip_if_neg: 1,
    skip_if_false: true,
  }

  CRITERIA_GROUPINGS = CRITERIA_VALUES.keys.group_by do |name|
    name.to_s[/^(.+?)(?:_part\d)?$/, 1]
  end.values.flat_map do |grouping|
    grouping.map{|name| [name, grouping] }
  end.to_h

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
        raise "empty #where args" if args.empty?
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

    criteria :datetime1, :datetime

    criteria %i[choice1_part1 choice1_part2], CRITERIA_CHOICES[:choice1_part1]

    criteria :choice2, CRITERIA_CHOICES[:choice2].values do |x|
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

  class MyInheritingSearch < MyModelSearch
    criteria :new_str1
  end

  def assert_results(criteria_values, results)
    expected = criteria_values.map{|k, v| [k, v, :OK] }.sort_by(&:first)
    actual = results.to_a.sort_by(&:first)
    assert_equal expected, actual
  end

end
