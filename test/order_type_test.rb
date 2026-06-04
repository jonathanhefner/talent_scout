require "test_helper"
require "talent_scout"

class OrderTypeTest < ActiveSupport::TestCase

  test "OrderType is a ChoiceType" do
    type = TalentScout::OrderType.new
    assert_kind_of TalentScout::ChoiceType, type
  end

  test "#definitions" do
    definitions = make_definitions(COLUMNS)
    type = make_type(definitions)
    assert_equal definitions.map(&:name), type.definitions.keys
  end

  test "#dup copies definitions" do
    type1 = make_type(make_definitions(COLUMNS))
    type2 = type1.dup
    assert_equal type1.definitions, type2.definitions
    assert_not_same type1.definitions, type2.definitions
  end

  test "#mapping" do
    definitions = make_definitions(COLUMNS)
    type = make_type(definitions)
    expected = definitions.flat_map do |definition|
      [ [definition.asc_choice, definition.asc_value],
        [definition.desc_choice, definition.desc_value] ]
    end
    assert_kind_of Hash, type.mapping
    assert_equal expected, type.mapping.to_a
  end

  test "#dup copies mapping" do
    type1 = make_type(make_definitions(COLUMNS))
    type2 = type1.dup
    assert_equal type1.mapping, type2.mapping
    assert_not_same type1.mapping, type2.mapping
  end

  test "#obverse_mapping" do
    definitions = make_definitions(COLUMNS)
    type = make_type(definitions)
    expected = definitions.flat_map do |definition|
      [ [definition.asc_value, { definition.name => :asc }],
        [definition.desc_value, { definition.name => :desc }] ]
    end.to_h
    assert_equal expected, type.obverse_mapping
  end

  test "#dup copies obverse_mapping" do
    type1 = make_type(make_definitions(COLUMNS))
    type2 = type1.dup
    assert_equal type1.obverse_mapping, type2.obverse_mapping
    assert_not_same type1.obverse_mapping, type2.obverse_mapping
  end

  test "cast unsuffixed order choice" do
    type = make_type(make_definitions(COLUMNS, asc_suffix: "_foo"))
    assert_equal type.cast("#{COLUMNS.first}_foo"), type.cast(COLUMNS.first.to_s)
    assert_equal type.cast("#{COLUMNS.first}_foo"), type.cast(COLUMNS.first.to_sym)
  end

  private

  COLUMNS = ["col1", "col2", "col3"]

  def make_definitions(columns, **options)
    columns.map{|column| TalentScout::OrderDefinition.new(column, [column], **options) }
  end

  def make_type(definitions)
    TalentScout::OrderType.new.tap do |type|
      definitions.each{|definition| type.add_definition(definition) }
    end
  end

end
