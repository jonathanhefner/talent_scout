require "test_helper"
require "talent_scout"

class OrMissingTypeTest < Minitest::Test

  def test_underlying_type_with_type
    type = ActiveModel::Type::Value.new
    assert_equal type, TalentScout::OrMissingType.new(type).underlying_type
  end

  def test_underlying_type_with_symbol
    type = ActiveModel::Type.lookup(:boolean)
    assert_equal type, TalentScout::OrMissingType.new(:boolean).underlying_type
  end

  def test_cast_with_valid_value
    type = TalentScout::OrMissingType.new(:date)
    date = Date.new(1999, 12, 31)
    assert_equal date, type.cast(date)
    assert_equal date, type.cast(date.to_s)
  end

  def test_cast_with_invalid_value
    type = TalentScout::OrMissingType.new(:date)
    assert_equal TalentScout::OrMissingType::MISSING, type.cast("BAD")
  end

  def test_cast_with_nil
    type = TalentScout::OrMissingType.new(:date)
    assert_nil type.cast(nil)
  end

  def test_attribute_assignment
    expected = 42
    model = MyModel.new(int1: expected.to_s)
    assert_equal expected, model.int1
  end

  private

  class MyModel
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :int1, TalentScout::OrMissingType.new(:integer)
  end

end
