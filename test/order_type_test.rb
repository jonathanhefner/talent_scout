require "test_helper"
require "talent_scout"

class OrderTypeTest < Minitest::Test

  def test_order_type_is_choice_type
    type = TalentScout::OrderType.new
    assert_kind_of TalentScout::ChoiceType, type
  end

  def test_definitions_after_add_definition
    definitions = make_definitions(COLUMNS)
    type = make_type(COLUMNS)
    assert_equal definitions.map(&:name), type.definitions.keys
  end

  def test_definitions_after_dup
    type1 = make_type(COLUMNS)
    type2 = type1.dup
    assert_equal type1.definitions, type2.definitions
    refute_same type1.definitions, type2.definitions
  end

  def test_mapping_after_add_definition
    definitions = make_definitions(COLUMNS)
    type = make_type(COLUMNS)
    expected = definitions.flat_map do |definition|
      [ [definition.asc_choice, definition.asc_value],
        [definition.desc_choice, definition.desc_value] ]
    end
    assert_kind_of Hash, type.mapping
    assert_equal expected, type.mapping.to_a
  end

  def test_mapping_after_dup
    type1 = make_type(COLUMNS)
    type2 = type1.dup
    assert_equal type1.mapping, type2.mapping
    refute_same type1.mapping, type2.mapping
  end

  def test_cast_unsuffixed_order_choice
    type = make_type(COLUMNS, asc_suffix: "_foo")
    assert_equal type.cast("#{COLUMNS.first}_foo"), type.cast(COLUMNS.first.to_s)
    assert_equal type.cast("#{COLUMNS.first}_foo"), type.cast(COLUMNS.first.to_sym)
  end

  private

  COLUMNS = ["col1", "col2", "col3"]

  def make_definitions(columns, **options)
    columns.map{|column| TalentScout::OrderDefinition.new(column, [column], options) }
  end

  def make_type(columns, **options)
    TalentScout::OrderType.new.tap do |type|
      columns.each{|column| type.add_definition(column, [column], options) }
    end
  end

end
