require "test_helper"
require "talent_scout"

class FormBuilderTest < ActionView::TestCase

  test "form action points to the model controller" do
    expected = form_builder_test_my_models_path
    assert_html_attribute "action", expected, build_form(MyModel.new) # sanity check
    assert_html_attribute "action", expected, build_form(MyModelSearch.new)
  end

  test "form uses scoped param keys" do
    field = make_text_field(:date1)
    assert_html_attribute "name", "#{TalentScout::PARAM_KEY}[date1]", field
  end

  test "form uses value_before_type_cast" do
    assert_not_equal SEARCH.date1_before_type_cast, SEARCH.date1.to_s # sanity check
    field = make_text_field(:date1)
    assert_html_attribute "value", SEARCH.date1_before_type_cast, field
  end

  test "select accepts each_choice's raw enum" do
    each_choice = SEARCH.each_choice(:choice1)
    choices = each_choice.to_a
    assert_equal options_for_select(choices), options_for_select(each_choice)
    assert_equal make_select_field(:choice1, choices), make_select_field(:choice1, each_choice)
  end

  test "select selects value_before_type_cast" do
    before_type_cast = SEARCH.choice1_before_type_cast
    selected = options_for_select([before_type_cast], selected: before_type_cast)
    field = make_select_field(:choice1, SEARCH.each_choice(:choice1))
    assert_includes field, selected
  end

  test "label uses I18n" do
    expected = "EXPECTED LABEL TEXT"
    I18n.backend.store_translations(:en,
      { activemodel: { attributes: { MyModelSearch.model_name.i18n_key => { date1: expected } } } })
    assert_includes make_field_label(:date1), expected
  end

  test "submit button default text" do
    assert_html_attribute "value", "Search", make_submit_button()
  end

  private

  class MyModel
    include ActiveModel::Model
  end

  class MyModelSearch < TalentScout::ModelSearch
    criteria :date1, :date
    criteria :choice1, choices: { "one" => 1, "two" => 2, "three" => 3 }
  end

  public def form_builder_test_my_models_path(*args) # mock route helper
    "/#{MyModel.model_name.route_key}"
  end

  SEARCH = MyModelSearch.new(date1: "December 31, 1999", choice1: "two")

  def build_form(model, &block)
    form_with(model: model, &block)
  end

  def make_form_builder
    @form_builder ||= build_form(SEARCH){|form| break form }
  end

  def make_text_field(name)
    make_form_builder.text_field(name)
  end

  def make_select_field(name, choices)
    make_form_builder.select(name, choices)
  end

  def make_field_label(name)
    make_form_builder.label(name)
  end

  def make_submit_button(value = nil)
    make_form_builder.submit(value)
  end

  def assert_html_attribute(attribute_name, expected_value, html)
    assert_includes html, " #{attribute_name}=\"#{expected_value}\""
  end

end
