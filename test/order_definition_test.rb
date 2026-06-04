require "test_helper"
require "talent_scout"

class OrderDefinitionTest < ActiveSupport::TestCase

  test "#name" do
    definition = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS)
    assert_equal "foo", definition.name
  end

  test "#asc_choice" do
    definition = make_definition(asc_suffix: "bar")
    assert_equal (definition.name + "bar"), definition.asc_choice
  end

  test "#desc_choice" do
    definition = make_definition(desc_suffix: "bar")
    assert_equal (definition.name + "bar"), definition.desc_choice
  end

  test "#desc_choice with only static columns" do
    definition = make_definition(STATIC_COLUMNS)
    assert_equal definition.asc_choice, definition.desc_choice
  end

  test "default suffixes" do
    definition = make_definition()
    assert_not_equal definition.asc_choice, definition.desc_choice
  end

  test "#asc_value" do
    definition = make_definition()
    expected = ALL_COLUMNS.join(", ")
    assert_equal Arel.sql(expected), definition.asc_value
  end

  test "#desc_value" do
    definition = make_definition()
    expected = (DYNAMIC_COLUMNS.map{|c| "#{c} DESC" } + STATIC_COLUMNS).join(", ")
    assert_equal Arel.sql(expected), definition.desc_value
  end

  test "columns as Symbols" do
    expected = make_definition(ALL_COLUMNS.map(&:to_s))
    actual = make_definition(ALL_COLUMNS.map(&:to_sym))
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  test "columns as a non-Array" do
    expected = make_definition(ALL_COLUMNS.take(1))
    actual = make_definition(ALL_COLUMNS.first)
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  test "columns as nil" do
    expected = make_definition([make_definition.name])
    actual = make_definition(nil)
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  test "#choice_for_direction with :asc" do
    definition = make_definition()
    [:asc, "asc", "ASC", true].each do |direction|
      assert_equal definition.asc_choice, definition.choice_for_direction(direction)
    end
  end

  test "#choice_for_direction with :desc" do
    definition = make_definition()
    [:desc, "desc", "DESC"].each do |direction|
      assert_equal definition.desc_choice, definition.choice_for_direction(direction)
    end
  end

  test "#choice_for_direction raises on an invalid direction" do
    definition = make_definition()
    assert_raises(ArgumentError){ definition.choice_for_direction(:bad) }
  end

  private

  DYNAMIC_COLUMNS = ["col1", "col2", "col3"]
  STATIC_COLUMNS = ["col4 ASC", "col5 asc", "col6 DESC", "col7 desc"]
  ALL_COLUMNS = DYNAMIC_COLUMNS + STATIC_COLUMNS

  def make_definition(columns = ALL_COLUMNS, **options)
    TalentScout::OrderDefinition.new("my_order", columns, **options)
  end

end
