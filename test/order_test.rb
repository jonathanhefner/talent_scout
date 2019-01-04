require "test_helper"
require "talent_scout"

class OrderTest < Minitest::Test

  def test_name
    order = TalentScout::Order.new("foo", ALL_COLUMNS)
    assert_equal "foo", order.name
  end

  def test_asc_choice
    order = TalentScout::Order.new("foo", ALL_COLUMNS, asc_suffix: "bar")
    assert_equal "foobar", order.asc_choice
  end

  def test_desc_choice
    order = TalentScout::Order.new("foo", ALL_COLUMNS, desc_suffix: "bar")
    assert_equal "foobar", order.desc_choice
  end

  def test_desc_choice_with_only_static_columns
    order = TalentScout::Order.new("foo", STATIC_COLUMNS)
    assert_equal order.asc_choice, order.desc_choice
  end

  def test_default_suffixes
    order = TalentScout::Order.new("foo", ALL_COLUMNS)
    refute_equal order.asc_choice, order.desc_choice
  end

  def test_asc_value
    order = TalentScout::Order.new("foo", ALL_COLUMNS)
    expected = ALL_COLUMNS.join(", ")
    assert_equal Arel.sql(expected), order.asc_value
  end

  def test_desc_value
    order = TalentScout::Order.new("foo", ALL_COLUMNS)
    expected = (DYNAMIC_COLUMNS.map{|c| "#{c} DESC" } + STATIC_COLUMNS).join(", ")
    assert_equal Arel.sql(expected), order.desc_value
  end

  def test_symbol_columns
    actual = TalentScout::Order.new("foo", ALL_COLUMNS.map(&:to_sym))
    expected = TalentScout::Order.new("foo", ALL_COLUMNS)
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  def test_singular_column
    actual = TalentScout::Order.new("foo", ALL_COLUMNS.first)
    expected = TalentScout::Order.new("foo", ALL_COLUMNS.take(1))
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  def test_nil_columns
    actual = TalentScout::Order.new("foo", nil)
    expected = TalentScout::Order.new("foo", ["foo"])
    assert_equal expected.asc_value, actual.asc_value
    assert_equal expected.desc_value, actual.desc_value
  end

  private

  DYNAMIC_COLUMNS = ["col1", "col2", "col3"]
  STATIC_COLUMNS = ["col4 ASC", "col5 asc", "col6 DESC", "col7 desc"]
  ALL_COLUMNS = DYNAMIC_COLUMNS + STATIC_COLUMNS

end
