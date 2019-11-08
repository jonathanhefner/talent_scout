require "test_helper"
require "talent_scout"

class ChoiceTypeTest < Minitest::Test

  def test_cast_with_valid_value
    type = TalentScout::ChoiceType.new(MAPPING)
    MAPPING.each do |value, expected|
      assert_equal expected, type.cast(value.to_sym)
      assert_equal expected, type.cast(value.to_s)
      assert_equal expected, type.cast(expected)
    end
  end

  def test_cast_with_invalid_value
    type = TalentScout::ChoiceType.new(MAPPING)
    assert_nil type.cast("BAD")
  end

  def test_mapping_with_hash
    type = TalentScout::ChoiceType.new(MAPPING)
    assert_kind_of Hash, type.mapping
    assert_equal MAPPING.stringify_keys.to_a, type.mapping.to_a
  end

  def test_mapping_with_array
    type = TalentScout::ChoiceType.new(MAPPING.values)
    assert_kind_of Hash, type.mapping
    assert_equal MAPPING.values.index_by(&:to_s).to_a, type.mapping.to_a
  end

  def test_raises_on_non_string_non_symbol_keys
    assert_raises(ArgumentError) do
      TalentScout::ChoiceType.new({ 1 => 1 })
    end
  end

  def test_dup_copies_mapping
    type1 = TalentScout::ChoiceType.new(MAPPING)
    type2 = type1.dup
    assert_equal type1.mapping, type2.mapping
    refute_same type1.mapping, type2.mapping
  end

  def test_attribute_assignment
    params = { choice1: MAPPING.first[0].to_s }
    expected = MAPPING.first[1]

    model = MyModel.new(params)
    assert_equal expected, model.choice1
  end

  private

  MAPPING = { one: 1, two: true, three: "abc", four: Date.new(2004, 04, 04) }

  class MyModel
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :choice1, TalentScout::ChoiceType.new(MAPPING)
  end

end
