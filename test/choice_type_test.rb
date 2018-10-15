require "test_helper"
require "talent_scout"

class ChoiceTypeTest < Minitest::Test

  def test_cast
    type = TalentScout::ChoiceType.new(CHOICES)

    CHOICES.each do |value, expected|
      assert_equal expected, type.cast(value)
      assert_equal expected, type.cast(value.to_s)
    end

    assert_nil type.cast("BAD")
  end

  def test_attribute_assignment
    params = { foo: CHOICES.first.first.to_s }
    expected = CHOICES.first.last

    model = MyModel.new(params)
    assert_equal expected, model.foo
  end

  private

  CHOICES = { one: 1, two: true, three: "abc", four: Date.new(2004, 04, 04) }

  class MyModel
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :foo, TalentScout::ChoiceType.new(CHOICES)
  end

end
