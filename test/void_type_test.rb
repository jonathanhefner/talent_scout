require "test_helper"
require "talent_scout"

class VoidTypeTest < ActiveSupport::TestCase

  test "underlying type is :boolean" do
    type = TalentScout::VoidType.new
    assert_equal ActiveModel::Type.lookup(:boolean), type.underlying_type
  end

  test "cast truthy values" do
    type = TalentScout::VoidType.new
    [true, "true", 1, "1"].each do |truthy|
      assert_equal true, type.cast(truthy)
    end
  end

  test "cast falsey values" do
    type = TalentScout::VoidType.new
    [false, "false", 0, "0", nil, ""].each do |falsey|
      assert_nil type.cast(falsey)
    end
  end

  test "attribute assignment" do
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
