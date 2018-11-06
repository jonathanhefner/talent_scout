require "test_helper"
require "talent_scout"

class FormBuilderTest < ActionView::TestCase

  def test_form_uses_value_before_type_cast
    before_type_cast = "December 31, 1999"
    search = MyModelSearch.new(date1: before_type_cast)
    refute_equal before_type_cast, search.date1.to_s # sanity check
    field = make_form(search).text_field(:date1)
    assert_includes field, before_type_cast
  end

  private

  class MyModel
  end

  class MyModelSearch < TalentScout::ModelSearch
    criteria :date1, :date
  end

  def make_form(search)
    form_with(model: search, url: "/"){|form| return form }
  end

end
