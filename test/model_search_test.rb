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
    assert_attributes CRITERIA_VALUES, search
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
    assert_attributes CRITERIA_VALUES, search
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
    assert_attributes CRITERIA_VALUES, search
  end

  def test_attribute_value_before_type_cast_readers
    before_type_cast = CRITERIA_VALUES.transform_values(&:to_s)
    search = MyModelSearch.new(before_type_cast)
    before_type_cast.each do |name, value|
      assert_equal value, search.send("#{name}_before_type_cast")
    end
  end

  def test_attribute_default_values
    expected = CRITERIA_VALUES.transform_values{ nil }.merge(CRITERIA_DEFAULT_VALUES)
    assert_attributes expected, MyModelSearch.new
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

  def test_default_scope
    search = MyOtherModelSearch.new
    assert_composition %i[scope1 scope2], search
  end

  def test_default_scope_is_inherited
    search = MyOtherInheritingSearch.new
    assert_composition %i[scope1 scope2 scope3], search
  end

  def test_default_scope_precedes_criteria
    search = MyOtherInheritingSearch.new(col1: "abc")
    assert_composition %i[scope1 scope2 scope3 col1], search
  end

  def test_results_with_full_criteria_values
    search = MyModelSearch.new(CRITERIA_VALUES)
    assert_results CRITERIA_VALUES, search
  end

  def test_inherits_criteria
    criteria_values = CRITERIA_VALUES.merge(new_str1: "new")
    search = MyInheritingSearch.new(criteria_values)
    assert_results criteria_values, search
  end

  def test_results_with_missing_criteria_values
    CRITERIA_VALUES.keys.each do |name|
      search = MyModelSearch.new(CRITERIA_VALUES.except(name))
      expected_values = CRITERIA_DEFAULT_VALUES.key?(name) ?
        CRITERIA_VALUES.merge(name => CRITERIA_DEFAULT_VALUES[name]) :
        CRITERIA_VALUES.except(*CRITERIA_GROUPINGS[name])
      assert_results expected_values, search
    end
  end

  def test_results_with_explicit_nil_criteria_values
    nilable = CRITERIA_VALUES.keys.grep(/^(?:str|date)\d/)
    refute_empty nilable # sanity check
    nilable.each do |name|
      criteria_values = CRITERIA_VALUES.merge(name => nil)
      search = MyModelSearch.new(criteria_values)
      assert_results criteria_values, search
    end
  end

  def test_results_with_invalid_criteria_values
    fallible = CRITERIA_VALUES.keys.grep(/^(?:date|choice)\d/)
    refute_empty fallible # sanity check
    fallible.each do |name|
      search = MyModelSearch.new(CRITERIA_VALUES.merge(name => "BAD"))
      expected_values = CRITERIA_VALUES.except(*CRITERIA_GROUPINGS[name])
      assert_results expected_values, search
    end
  end

  def test_results_with_base_scope
    base_params = { base_str1: "hello", base_str2: "world" }
    base_scope = MyModel.all.where(base_params)
    criteria_values = base_params.merge(CRITERIA_VALUES)
    assert_results criteria_values, MyModelSearch.new(CRITERIA_VALUES) do |search|
      search.results(base_scope)
    end
  end

  def test_results_skips_conditional_criteria_block
    search = MyModelSearch.new(CRITERIA_VALUES.merge(skip_if_neg: -1))
    assert_results CRITERIA_VALUES.except(:skip_if_neg), search
  end

  def test_results_skips_void_type_criteria
    search = MyModelSearch.new(CRITERIA_VALUES.merge(skip_if_false: false))
    assert_results CRITERIA_VALUES.except(:skip_if_false), search
  end

  def test_modify_via_with
    search1 = MyModelSearch.new
    search2 = search1.with(CRITERIA_VALUES)
    refute_equal search1.results, search2.results
    assert_results CRITERIA_VALUES, search2
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
    assert_results CRITERIA_VALUES.merge(CRITERIA_DEFAULT_VALUES), search2
  end

  def test_modify_via_without_raises_on_invalid_criteria_name
    search = MyModelSearch.new(CRITERIA_VALUES)
    assert_raises ActiveModel::UnknownAttributeError do
      search.without(:bad)
    end
  end

  def test_modify_via_toggle_order
    order_choices = ORDER_COLUMNS.keys.zip(CRITERIA_CHOICES[:order].keys.each_slice(2))

    order_choices.each do |order, choices|
      toggles = choices.zip(choices.reverse).append([nil, choices.first])
      toggles.each do |choice, toggled|
        search = MyModelSearch.new(order: choice)
        assert_equal toggled.to_s, search.toggle_order(order).order
        assert_equal choices.first.to_s, search.toggle_order(order, :asc).order
        assert_equal choices.last.to_s, search.toggle_order(order, :desc).order
        assert_same choice, search.order # unmodified
      end
    end
  end

  def test_modify_via_toggle_order_raises_on_invalid_order_name
    search = MyModelSearch.new
    assert_raises(ArgumentError){ search.toggle_order("BAD") }
  end

  def test_modify_via_toggle_order_raises_on_invalid_direction
    search = MyModelSearch.new
    assert_raises(ArgumentError){ search.toggle_order(ORDER_COLUMNS.keys.first, :bad) }
  end

  def test_each_choice
    chosen = CRITERIA_CHOICES.transform_values{|mapping| mapping.keys[1] }
    search = MyModelSearch.new(chosen)

    CRITERIA_CHOICES.each do |name, mapping|
      expected = mapping.keys.map{|choice| [choice.to_s, choice == chosen[name]] }

      assert_equal expected, search.each_choice(name.to_sym).map{|k, v| [k, v] }
      assert_equal expected, search.each_choice(name.to_s).map{|k, v| [k, v] }
    end
  end

  def test_each_choice_sensitive_to_block_arity
    criteria = CRITERIA_CHOICES.keys.first
    search = MyModelSearch.new
    expected = search.each_choice(criteria).map{|k, v| k }
    actual = search.each_choice(criteria).to_a
    assert_equal expected, actual
  end

  def test_each_choice_block_and_enum_are_equivalent
    criteria = CRITERIA_CHOICES.keys.first
    search = MyModelSearch.new
    block_values = []
    search.each_choice(criteria){|k, v| block_values << [k, v] }
    assert_instance_of Enumerator, search.each_choice(criteria)
    enum_values = search.each_choice(criteria).map{|k, v| [k, v] }
    assert_equal block_values, enum_values
  end

  def test_each_choice_raises_on_invalid_criteria_name
    search = MyModelSearch.new
    (CRITERIA_VALUES.keys - CRITERIA_CHOICES.keys + [:bad]).each do |name|
      assert_raises(ArgumentError){ search.each_choice(name) }
    end
  end

  def test_order_accessor_inherits_before_type_cast_behavior
    expected = "col1_desc"
    actual = MyInheritingSearch.new(order: expected).order
    assert_equal expected, actual
  end

  def test_order_choices_are_inherited
    expected = CRITERIA_CHOICES[:order].keys.map(&:to_s) + ["new_col1.asc", "new_col1.desc"]
    actual = MyInheritingSearch.new.each_choice(:order).to_a
    assert_equal expected, actual
  end

  def test_order_default_is_inherited
    expected = MyModelSearch.new.order
    actual = MyInheritingSearch.new.order
    assert_equal expected, actual
  end

  def test_order_default_can_be_overridden
    expected = MyReorderedInheritingSearch.new.toggle_order("new_col1", :desc).order
    actual = MyReorderedInheritingSearch.new.order
    assert_equal expected, actual
  end

  def test_order_default_not_specified
    assert_nil MyOrderableModelSearch.new.order
  end

  def test_order_columns_can_be_overridden
    original = MyModelSearch.attribute_types["order"].cast("col2")
    refute_includes original, "new_col1 ASC"
    actual = MyInheritingSearch.attribute_types["order"].cast("col2")
    assert_includes actual, "new_col1 ASC"
  end

  def test_order_directions
    choice_directions = CRITERIA_CHOICES[:order].keys.zip([:asc, :desc].cycle).to_h
    order_choices = ORDER_COLUMNS.keys.zip(CRITERIA_CHOICES[:order].keys.each_slice(2))
    expected_base = ORDER_COLUMNS.transform_values{ nil }.with_indifferent_access

    order_choices.each do |order, choices|
      (choices.map(&:to_sym) + choices.map(&:to_s)).each do |choice|
        search = MyModelSearch.new(order: choice)
        expected = expected_base.merge(order => choice_directions[choice.to_sym])
        assert_equal expected, search.order_directions
      end
    end
  end

  def test_order_directions_with_unsuffixed_order_choice
    search1 = MyModelSearch.new(order: "col1_asc")
    search2 = MyModelSearch.new(order: :col1)
    assert_equal search1.order_directions, search2.order_directions
  end

  def test_order_directions_with_no_order_specified
    search = MyOrderableModelSearch.new
    expected = { col1: nil }.with_indifferent_access
    assert_equal expected, search.order_directions
  end

  def test_order_directions_with_no_orders_defined
    search = MyOtherModelSearch.new
    assert_equal ({}), search.order_directions
  end

  def test_order_directions_frozen
    assert MyModelSearch.new.order_directions.frozen?
    assert MyOtherModelSearch.new.order_directions.frozen?
  end

  def test_to_query_params_returns_values_before_type_cast
    before_type_cast = CRITERIA_VALUES.transform_values(&:to_s)
    search = MyModelSearch.new(before_type_cast)
    assert_equal before_type_cast.stringify_keys, search.to_query_params
  end

  def test_to_query_params_ignores_default_values
    default_values = CRITERIA_VALUES.transform_values{ nil }.merge(CRITERIA_DEFAULT_VALUES)
    search = MyModelSearch.new(default_values)
    assert_equal Hash.new, search.to_query_params
  end

  private

  CRITERIA_CHOICES = {
    choice1_part1: { foo: "foo", bar: "bar" },
    choice1_part2: { foo: "foo", bar: "bar" },
    choice2: { "1" => 1, "2" => 2, "99" => 99, "100" => 100 },
    order: %w"col1_asc col1_desc col2.asc col2.desc random random_is_random".index_by(&:to_sym),
  }

  ORDER_COLUMNS = {
    col1: ["col1"],
    col2: ["col2", "col1 ASC"],
    random: ["RAND()"],
  }

  CRITERIA_DEFAULT_VALUES = {
    str2: "abcdefault",
    date2_part1: Date.new(1970, 01, 01),
    date2_part2: Date.new(1970, 01, 01),
    order: "col1_asc",
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
    choice1_part1: "foo",
    choice1_part2: "bar",
    choice2: 99,
    skip_if_neg: 1,
    skip_if_false: true,
    order: "col2.asc",
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
          raise "order passed to #where" if name == :order
          rel.append(name, value)
        end
      end

      def order(arg)
        append(:order, arg)
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

    criteria %i[choice1_part1 choice1_part2], choices: CRITERIA_CHOICES[:choice1_part1]

    criteria :choice2, choices: CRITERIA_CHOICES[:choice2].values do |x|
      append(:choice2, x)
    end

    criteria :skip_if_neg, :integer do |x|
      append(:skip_if_neg, x) unless x < 0
    end

    criteria :skip_if_false, :void do
      append(:skip_if_false, true)
    end

    order :col1, asc_suffix: "_asc", desc_suffix: "_desc", default: true
    order :col2, ORDER_COLUMNS[:col2]
    order :random, ORDER_COLUMNS[:random], asc_suffix: "", desc_suffix: "_is_random"
  end

  class MyInheritingSearch < MyModelSearch
    criteria :new_str1

    order :new_col1
    order :col2, [*ORDER_COLUMNS[:col2], "new_col1 ASC"]
  end

  class MyReorderedInheritingSearch < MyModelSearch
    order :new_col1, default: :desc
  end

  class MyOtherModelSearch < TalentScout::ModelSearch
    model MyModel
    default_scope { append(:scope1, true) }
    default_scope { append(:scope2, true) }
    criteria :col1
  end

  class MyOtherInheritingSearch < MyOtherModelSearch
    default_scope { append(:scope3, true) }
  end

  class MyOrderableModelSearch < TalentScout::ModelSearch
    model MyModel
    order :col1 # not default
  end

  def assert_attributes(criteria_values, search)
    expected = criteria_values.map do |key, value|
      type = search.class.attribute_types[key.to_s]
      [key.to_s, type.cast(value)]
    end.to_h
    assert_equal expected, search.attributes
  end

  def assert_results(criteria_values, search)
    results = block_given? ? yield(search) : search.results
    expected = criteria_values.map do |key, value|
      type = search.class.attribute_types[key.to_s]
      [key, type.cast(value), :OK]
    end.sort_by(&:first)
    actual = results.to_a.sort_by(&:first)
    assert_equal expected, actual
  end

  def assert_composition(names, search)
    assert_equal names, search.results.to_a.map(&:first)
  end

end
