require "test_helper"
require "talent_scout"

class FormBuilderTest < ActionView::TestCase

  def test_form_action_points_to_model_controller
    assert_equal form_with(model: MyModel.new), form_with(model: MyModelSearch.new)
  end

  def test_form_uses_specified_params_wrapper
    field_name = :date1
    expected = text_field TalentScout::ModelName::PARAM_KEY, field_name
    actual = make_form(MyModelSearch.new).text_field(field_name)
    assert_equal expected, actual
  end

  def test_form_uses_value_before_type_cast
    before_type_cast = "December 31, 1999"
    search = MyModelSearch.new(date1: before_type_cast)
    refute_equal before_type_cast, search.date1.to_s # sanity check
    field = make_form(search).text_field(:date1)
    assert_includes field, before_type_cast
  end

  def test_select_selects_value_before_type_cast
    before_type_cast = "two"
    search = MyModelSearch.new(choice1: before_type_cast)
    field = make_form(search).select(:choice1, search.choices_for(:choice1))
    selected = options_for_select([before_type_cast], selected: before_type_cast)
    assert_includes field, selected
  end

  private

  class MyModel
    include ActiveModel::Model
  end

  class MyModelSearch < TalentScout::ModelSearch
    criteria :date1, :date
    criteria :choice1, { "one" => 1, "two" => 2, "three" => 3 }
  end

  def form_builder_test_my_models_path(*args) # mock route helper
    "/#{MyModel.model_name.route_key}"
  end

  def make_form(search)
    form_with(model: search){|form| return form }
  end

end
