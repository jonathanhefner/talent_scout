require "test_helper"
require "talent_scout"

class VoidTypeTest < Minitest::Test

  def test_underlying_type
    type = TalentScout::VoidType.new
    assert_equal ActiveModel::Type.lookup(:boolean), type.underlying_type
  end

  def test_cast_truthy
    type = TalentScout::VoidType.new
    [true, "true", 1, "1"].each do |truthy|
      assert_equal true, type.cast(truthy)
    end
  end

  def test_cast_falsey
    type = TalentScout::VoidType.new
    [false, "false", 0, "0", nil, ""].each do |falsey|
      assert_equal TalentScout::VoidType::MISSING, type.cast(falsey)
    end
  end

  def test_cast_missing
    type = TalentScout::VoidType.new
    assert_equal TalentScout::VoidType::MISSING, type.cast(TalentScout::VoidType::MISSING)
  end

  def test_attribute_assignment
    expected = true
    model = MyModel.new(void1: expected.to_s)
    assert_equal expected, model.void1
  end

  private

  class MyModel
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :void1, TalentScout::VoidType.new
  end

end
