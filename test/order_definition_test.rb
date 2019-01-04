require "test_helper"
require "talent_scout"

class OrderDefinitionTest < Minitest::Test

  def test_name
    definition = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS)
    assert_equal "foo", definition.name
  end

  def test_asc_choice
    definition = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS, asc_suffix: "bar")
    assert_equal "foobar", definition.asc_choice
  end

  def test_desc_choice
    definition = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS, desc_suffix: "bar")
    assert_equal "foobar", definition.desc_choice
  end

  def test_desc_choice_with_only_static_columns
    definition = TalentScout::OrderDefinition.new("foo", STATIC_COLUMNS)
    assert_equal definition.asc_choice, definition.desc_choice
  end

  def test_default_suffixes
    definition = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS)
    refute_equal definition.asc_choice, definition.desc_choice
  end

  def test_asc_value
    definition = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS)
    expected = ALL_COLUMNS.join(", ")
    assert_equal Arel.sql(expected), definition.asc_value
  end

  def test_desc_value
    definition = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS)
    expected = (DYNAMIC_COLUMNS.map{|c| "#{c} DESC" } + STATIC_COLUMNS).join(", ")
    assert_equal Arel.sql(expected), definition.desc_value
  end

  def test_symbol_columns
    actual = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS.map(&:to_sym))
    expected = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS)
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  def test_singular_column
    actual = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS.first)
    expected = TalentScout::OrderDefinition.new("foo", ALL_COLUMNS.take(1))
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  def test_nil_columns
    actual = TalentScout::OrderDefinition.new("foo", nil)
    expected = TalentScout::OrderDefinition.new("foo", ["foo"])
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  private

  DYNAMIC_COLUMNS = ["col1", "col2", "col3"]
  STATIC_COLUMNS = ["col4 ASC", "col5 asc", "col6 DESC", "col7 desc"]
  ALL_COLUMNS = DYNAMIC_COLUMNS + STATIC_COLUMNS

end
