require "test_helper"
require "talent_scout"

class FormBuilderTest < ActionView::TestCase

  def test_form_action_points_to_model_controller
    assert_equal form_with(model: MyModel.new), form_with(model: MyModelSearch.new)
  end

  def test_form_uses_specified_params_wrapper
    field = make_form.text_field(:date1)
    assert_html_attribute "name", "#{TalentScout::PARAM_KEY}[date1]", field
  end

  def test_form_uses_value_before_type_cast
    refute_equal SEARCH.date1_before_type_cast, SEARCH.date1.to_s # sanity check
    field = make_form.text_field(:date1)
    assert_html_attribute "value", SEARCH.date1_before_type_cast, field
  end

  def test_select_accepts_each_choice_raw_enum
    each_choice = SEARCH.each_choice(:choice1)
    choices = each_choice.to_a.map(&:first)
    form = make_form
    assert_equal options_for_select(choices), options_for_select(each_choice)
    assert_equal form.select(:choice1, choices), form.select(:choice1, each_choice)
  end

  def test_select_selects_value_before_type_cast
    before_type_cast = SEARCH.choice1_before_type_cast
    selected = options_for_select([before_type_cast], selected: before_type_cast)
    field = make_form.select(:choice1, SEARCH.each_choice(:choice1))
    assert_includes field, selected
  end

  def test_submit_button_default_text
    assert_html_attribute "value", "Search", make_form.submit
  end

  private

  class MyModel
    include ActiveModel::Model
  end

  class MyModelSearch < TalentScout::ModelSearch
    criteria :date1, :date
    criteria :choice1, choices: { "one" => 1, "two" => 2, "three" => 3 }
  end

  def form_builder_test_my_models_path(*args) # mock route helper
    "/#{MyModel.model_name.route_key}"
  end

  SEARCH = MyModelSearch.new(date1: "December 31, 1999", choice1: "two")

  def make_form(search = SEARCH)
    form_with(model: search){|form| return form }
  end

  def assert_html_attribute(attribute_name, expected_value, html)
    assert_includes html, " #{attribute_name}=\"#{expected_value}\""
  end

end
