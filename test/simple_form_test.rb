silence_warnings{ require "simple_form" }
require_relative "form_builder_test"

class SimpleFormTest < FormBuilderTest

  include SimpleForm::ActionViewExtensions::FormHelper

  def test_attribute_type_detection
    expected = make_form_builder.input(:date1, as: :date)
    actual = make_form_builder.input(:date1)
    assert_equal expected, actual
  end

  private

  def build_form(model, &block)
    block ||= Proc.new{}
    simple_form_for(model, &block)
  end

  def make_text_field(name)
    make_form_builder.input(name, as: :string)
  end

  def make_select_field(name, choices)
    make_form_builder.input(name, collection: choices)
  end

  def make_field_label(name)
    make_text_field(name)
  end

  def make_submit_button(value = nil)
    make_form_builder.button(:submit)
  end

end
