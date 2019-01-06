require "test_helper"
require "talent_scout"

class OrderDefinitionTest < Minitest::Test

  def test_name
    definition = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS)
    assert_equal "foo", definition.name
  end

  def test_asc_choice
    definition = make_definition(asc_suffix: "bar")
    assert_equal (definition.name + "bar"), definition.asc_choice
  end

  def test_desc_choice
    definition = make_definition(desc_suffix: "bar")
    assert_equal (definition.name + "bar"), definition.desc_choice
  end

  def test_desc_choice_with_only_static_columns
    definition = make_definition(STATIC_COLUMNS)
    assert_equal definition.asc_choice, definition.desc_choice
  end

  def test_default_suffixes
    definition = make_definition()
    refute_equal definition.asc_choice, definition.desc_choice
  end

  def test_asc_value
    definition = make_definition()
    expected = ALL_COLUMNS.join(", ")
    assert_equal Arel.sql(expected), definition.asc_value
  end

  def test_desc_value
    definition = make_definition()
    expected = (DYNAMIC_COLUMNS.map{|c| "#{c} DESC" } + STATIC_COLUMNS).join(", ")
    assert_equal Arel.sql(expected), definition.desc_value
  end

  def test_symbol_columns
    expected = make_definition(ALL_COLUMNS.map(&:to_s))
    actual = make_definition(ALL_COLUMNS.map(&:to_sym))
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  def test_singular_column
    expected = make_definition(ALL_COLUMNS.take(1))
    actual = make_definition(ALL_COLUMNS.first)
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  def test_nil_columns
    expected = make_definition([make_definition.name])
    actual = make_definition(nil)
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  private

  DYNAMIC_COLUMNS = ["col1", "col2", "col3"]
  STATIC_COLUMNS = ["col4 ASC", "col5 asc", "col6 DESC", "col7 desc"]
  ALL_COLUMNS = DYNAMIC_COLUMNS + STATIC_COLUMNS

  def make_definition(columns = ALL_COLUMNS, **options)
    TalentScout::OrderDefinition.new("my_order", columns, options)
  end

end
