require "test_helper"
require "talent_scout"

class LinkToSearchTest < ActionView::TestCase

  # Manually include the helper module, because although the railtie
  # indiomatically loads the TalentScout::Helper module into
  # ActionView::Base, ActionView::TestCase does not descend from
  # ActionView::Base
  include TalentScout::Helper

  def test_helper_loaded_by_railtie
    assert_includes ActionView::Base.included_modules, TalentScout::Helper
  end

  def test_links_to_search
    assert_search_link link_to_search(LINK_TEXT, SEARCH, HTML_OPTIONS)
  end

  def test_supports_contents_block
    assert_search_link link_to_search(SEARCH, HTML_OPTIONS){ LINK_TEXT }
  end

  def test_defaults_to_current_controller
    @controller_path = MyOtherModelsController.controller_path
    assert_search_link link_to_search(LINK_TEXT, SEARCH, HTML_OPTIONS),
      controller: @controller_path
  end

  def test_supports_override_controller
    options = { controller: MyOtherModelsController.controller_path, search: SEARCH }
    assert_search_link link_to_search(LINK_TEXT, options, HTML_OPTIONS), **options
  end

  def test_defaults_to_current_action
    @action_name = "new"
    assert_search_link link_to_search(LINK_TEXT, SEARCH, HTML_OPTIONS),
      action: @action_name
  end

  def test_supports_override_action
    options = { action: "new", search: SEARCH }
    assert_search_link link_to_search(LINK_TEXT, options, HTML_OPTIONS), **options
  end

  def test_supports_extra_query_params
    actual = link_to_search(LINK_TEXT, { search: SEARCH, per_page: 100 }, HTML_OPTIONS)
    actual_href = Nokogiri::HTML(actual).at_css("a")["href"]
    assert_includes URI(actual_href).query.split("&"), "per_page=100"
  end

  def test_html_options_are_optional
    assert link_to_search(LINK_TEXT, SEARCH)
    assert link_to_search(SEARCH){ LINK_TEXT }
  end

  def test_raises_on_nil_search
    assert_raises(ArgumentError){ link_to_search(LINK_TEXT, nil, HTML_OPTIONS) }
    assert_raises(ArgumentError){ link_to_search(LINK_TEXT) }
    assert_raises(ArgumentError){ link_to_search(LINK_TEXT, { action: "index" }) }
    assert_raises(ArgumentError){ link_to_search{ LINK_TEXT } }
  end

  private

  class MyModelSearch < TalentScout::ModelSearch
    criteria :str1
    criteria :str2
  end

  class MyModelsController < ActionController::Base
  end

  class MyOtherModelsController < ActionController::Base
  end

  def controller_path
    super # sanity check base method exists
    @controller_path ||= MyModelsController.controller_path
  end

  def action_name
    super # sanity check base method exists
    @action_name ||= "index"
  end

  def link_to(*args)
    @routes ||= nil # silence Rails warning
    with_routing do |set|
      set.draw do
        resources :my_models, module: :link_to_search_test
        resources :my_other_models, module: :link_to_search_test
      end
      super
    end
  end

  SEARCH = MyModelSearch.new(str1: "foo", str2: "bar")
  LINK_TEXT = "<b>My Link</b>".html_safe
  HTML_OPTIONS = { class: "abc", id: "123", target: "_blank" }

  def assert_search_link(actual, search: SEARCH, controller: controller_path, action: action_name)
    options = {
      controller: controller,
      action: action,
      MyModelSearch.model_name.param_key => search.to_query_params,
    }
    expected = link_to(LINK_TEXT, options, HTML_OPTIONS)
    assert_equal expected, actual
  end

end
