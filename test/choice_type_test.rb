require "test_helper"
require "talent_scout"

class ChoiceTypeTest < Minitest::Test

  def test_cast_with_valid_value
    type = TalentScout::ChoiceType.new(CHOICES)
    CHOICES.each do |value, expected|
      assert_equal expected, type.cast(expected)
      assert_equal expected, type.cast(value)
      assert_equal expected, type.cast(value.to_s)
    end
  end

  def test_cast_with_invalid_value
    type = TalentScout::ChoiceType.new(CHOICES)
    assert_nil type.cast("BAD")
  end

  def test_choices_with_array
    type = TalentScout::ChoiceType.new(CHOICES.values)
    CHOICES.values.each do |expected|
      assert_equal expected, type.cast(expected)
      assert_equal expected, type.cast(expected.to_s)
    end
  end

  def test_choices_with_aliasing_keys
    type = TalentScout::ChoiceType.new({ "foo" => true, foo: true })
    assert_equal true, type.cast("foo")
    assert_equal true, type.cast(:foo)
  end

  def test_choices_with_conflicting_values
    assert_raises(ArgumentError) do
      TalentScout::ChoiceType.new({ "foo" => true, foo: false })
    end
  end

  def test_choices_with_self_referential_key
    type = TalentScout::ChoiceType.new({ "foo" => true, true => true })
    assert_equal true, type.cast("foo")
    assert_equal true, type.cast(true)
  end

  def test_choices_with_ambiguous_key_value
    assert_raises(ArgumentError) do
      TalentScout::ChoiceType.new({ "foo" => true, true => 2 })
    end
  end

  def test_attribute_assignment
    params = { choice1: CHOICES.first[0].to_s }
    expected = CHOICES.first[1]

    model = MyModel.new(params)
    assert_equal expected, model.choice1
  end

  private

  CHOICES = { one: 1, two: true, three: "abc", four: Date.new(2004, 04, 04) }

  class MyModel
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :choice1, TalentScout::ChoiceType.new(CHOICES)
  end

end
