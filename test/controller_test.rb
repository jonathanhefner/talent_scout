require "test_helper"
require "talent_scout"

class ControllerTest < Minitest::Test

  def test_model_search_class_getter
    assert_includes MyModelSearch.name, "::" # sanity check is namespaced class
    assert_equal MyModelSearch, MyModelsController.model_search_class
  end

  def test_model_search_class_setter
    MyModelsController.model_search_class = MyOtherModelSearch
    assert_equal MyOtherModelSearch, MyModelsController.model_search_class
  ensure
    MyModelsController.model_search_class = MyModelSearch # restore
  end

  def test_model_search_without_params
    controller = make_controller
    search = controller.model_search
    assert_instance_of MyModelSearch, search
    assert_equal MyModelSearch.new.attributes, search.attributes
  end

  def test_model_search_with_params
    criteria_values = { str1: "expected" }
    controller = make_controller(MyModelSearch.model_name.param_key => criteria_values)
    search = controller.model_search
    assert_instance_of MyModelSearch, search
    assert_equal criteria_values, search.attributes.symbolize_keys
  end

  def test_model_search_with_custom_search_class
    criteria_values = { str2: "expected" }
    controller = make_controller(MyOtherModelSearch.model_name.param_key => criteria_values)
    search = controller.model_search(MyOtherModelSearch)
    assert_instance_of MyOtherModelSearch, search
    assert_equal criteria_values, search.attributes.symbolize_keys
  end

  private

  class MyModel
  end

  class MyModelSearch < TalentScout::ModelSearch
    criteria :str1
  end

  class MyOtherModelSearch < TalentScout::ModelSearch
    criteria :str2
  end

  class MyModelsController < ActionController::Base
  end

  def make_controller(params = {})
    MyModelsController.new.tap do |controller|
      controller.params = ActionController::Parameters.new(params)
    end
  end

end
