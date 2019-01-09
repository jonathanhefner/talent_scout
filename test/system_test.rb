require "test_helper"
require "talent_scout"


Post.class_eval do
  enum category: [:science, :technology, :engineering, :math]
end

class PostSearch < TalentScout::ModelSearch
  criteria :title_end_with do |ending|
    where("title LIKE ?", "%#{ending}")
  end

  criteria :category, choices: Post.categories

  criteria :published, :boolean, default: true

  order :created_at, default: :desc
end

$expected_search = nil

PostsController.class_eval do
  def index
    @posts = model_search.results

    render layout: true, inline: <<~ERB
      <p id="ids"><%= @posts.pluck(:id).join(",") %></p>

      <%= link_to_search "Search", $expected_search, id: "search-link" %>

      <%= form_with model: $expected_search, method: :get do |form| %>
        <%= form.text_field :title_end_with %>
        <%= form.select :category, $expected_search.each_choice(:category),
              include_blank: true %>
        <%= form.check_box :published %>
        <%= form.submit id: "search-submit" %>
      <% end %>
    ERB
  end
end


class SystemTest < ActionDispatch::SystemTestCase

  driven_by :rack_test
  fixtures :posts

  def test_various_searches
    combinations = [nil, "1", "2"].product([nil, :technology, :math], [nil, true, false])

    combinations.each do |title_end_with, category, published|
      criteria_values = { title_end_with: title_end_with, category: category, published: published }
      search_and_verify(criteria_values.compact)
    end
  end

  private

  def search_and_verify(criteria_values)
    $expected_search = PostSearch.new(criteria_values)
    ["#search-link", "#search-submit"].each do |target|
      visit posts_path
      verify_ids(PostSearch.new)
      find(target).click
      verify_ids($expected_search)
    end
  end

  def verify_ids(search)
    expected = search.results.pluck(:id).join(",")
    actual = find("#ids").text
    assert_equal expected, actual
  end

end
