require "test_helper"
require "talent_scout"

class ControllerTest < ActiveSupport::TestCase

  test "model_search_class" do
    assert_includes MyModelSearch.name, "::" # sanity check is namespaced class
    assert_equal MyModelSearch, MyModelsController.model_search_class
  end

  test "model_search_class raises when the search class does not exist" do
    assert_raises{ NoSearchController.model_search_class }
  end

  test "model_search_class?" do
    assert_equal MyModelSearch, MyModelsController.model_search_class?
  end

  test "model_search_class? does not raise when the search class does not exist" do
    assert_not NoSearchController.model_search_class? # does not raise
  end

  test "model_search with params" do
    search = make_controller(MyModelsController, CRITERIA_VALUES).model_search
    assert_instance_of MyModelSearch, search
    assert_equal CRITERIA_VALUES, search.attributes.symbolize_keys
  end

  test "model_search without params" do
    search = make_controller(MyModelsController, nil).model_search
    assert_instance_of MyModelSearch, search
    assert_equal MyModelSearch.new.attributes, search.attributes
  end

  test "model_search with a custom search class" do
    search = make_controller(MyOtherController, CRITERIA_VALUES).model_search
    assert_instance_of MyModelSearch, search
    assert_equal CRITERIA_VALUES, search.attributes.symbolize_keys
  end

  private

  class MyModel
  end

  class MyModelSearch < TalentScout::ModelSearch
    criteria :str1
  end

  class MyModelsController < ActionController::Base
  end

  class MyOtherController < ActionController::Base
    self.model_search_class = MyModelSearch
  end

  class NoSearchController < ActionController::Base
  end

  CRITERIA_VALUES = { str1: "foo" }

  def make_controller(controller_class, criteria_values)
    controller_class.new.tap do |controller|
      controller.params = ActionController::Parameters.new({
        MyModelSearch.model_name.param_key => criteria_values.presence
      }.compact)
    end
  end

end
