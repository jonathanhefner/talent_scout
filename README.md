# talent_scout [![Build Status](https://travis-ci.org/jonathanhefner/talent_scout.svg?branch=master)](https://travis-ci.org/jonathanhefner/talent_scout)

Model-backed searches in Rails.  A whiz-bang example:

```ruby
## app/searches/post_search.rb

class PostSearch < TalentScout::ModelSearch
  criteria :title_includes do |string|
    where("title LIKE ?", "%#{string}%")
  end

  criteria :within, choices: {
    "Last 24 hours" => 24.hours,
    "Past Week" => 1.week,
    "Past Month" => 1.month,
    "Past Year" => 1.year,
  } do |duration|
    where("created_at >= ?", duration.ago)
  end

  criteria :only_published, :boolean, default: true do |only|
    where("published") if only
  end

  order :created_at, default: :desc
  order :title
end
```

```ruby
## app/controllers/posts_controller.rb

class PostsController < ApplicationController
  def index
    @search = model_search
    @posts = @search.results
  end
end
```

```html+erb
<!-- app/views/posts/index.html.erb -->

<%= form_with model: @search, local: true, method: :get do |form| %>
  <%= form.label :title_includes %>
  <%= form.text_field :title_includes %>

  <%= form.label :within %>
  <%= form.select :within, @search.each_choice(:within), include_blank: true %>

  <%= form.label :only_published %>
  <%= form.check_box :only_published %>

  <%= form.submit %>
<% end %>

<table>
  <thead>
    <tr>
      <th>
        <%= link_to_search "Title", @search.toggle_order(:title) %>
        <%= img_tag "#{@search.order_directions[:title] || "unsorted"}_icon.png" %>
      </th>
      <th>
        <%= link_to_search "Time", @search.toggle_order(:created_at) %>
        <%= img_tag "#{@search.order_directions[:created_at] || "unsorted"}_icon.png" %>
      </th>
    </tr>
  </thead>
  <tbody>
    <% @posts.each do |post| %>
      <tr>
        <td><%= link_to post.title, post %></td>
        <td><%= post.created_at %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

In the above example:

* The `PostSearch` class handles the responsibility of searching for
  `Post` models.  It can apply any combination of its defined criteria,
  automatically ignoring missing, blank, or invalid input values.  It
  can also order the results by one of its defined orders, in either
  ascending or descending direction.
* `PostsController#index` uses the `model_search` helper to construct a
  `PostSearch` instance, and assigns it to the `@search` variable for
  later use in the view.  The search results are also assigned to a
  variable for use in the view.
* The view uses Rails' stock form builder to build a search form with
  the `@search` variable.  The `link_to_search` helper is used to create
  links in the table header which sort the results.  Note that the
  `toggle_order` method used here returns a new search object, leaving
  `@search` unmodified.

For a detailed explanation of the methods used in this example, see
the [API documentation](https://www.rubydoc.info/gems/talent_scout/).


## Search Classes

You can use the `talent_scout:search` generator to generate a model
search class definition.  For example,

```bash
$ rails generate talent_scout:search post
```

Will generate a file "app/searches/post_search.rb" containing:

```ruby
class PostSearch < TalentScout::ModelSearch
end
```

Search classes inherit from `TalentScout::ModelSearch`.  Their target
model class is inferred from the search class name.  For example,
`PostSearch` will search for `Post` models by default.  To override this
inference, use `ModelSearch::model_class=`:

```ruby
class EmployeeSearch < TalentScout::ModelSearch
  self.model_class = Person # search for Person models instead of `Employee`
end
```


### Criteria

Search criteria are defined with the `ModelSearch::criteria` method.
Criteria definitions can be specified in one of three ways: with an
implicit where clause, with an explicit query block, or with a model
scope reference.  To illustrate, the following three `:title` criteria
are all equivalent:

```ruby
class Post < ActiveRecord::Base
  scope :title_equals, ->(string){ where(title: string) }
end

class PostSearch < TalentScout::ModelSearch
  criteria :title

  criteria :title do |string|
    where(title: string)
  end

  criteria :title, &:title_equals
end
```

Note that explicit query blocks are evaluated in the context of the
model's `ActiveRecord::Relation`, just like Active Record `scope` blocks
are.


#### Criteria Type

A criteria definition can specify a data type, which causes its input
value to be typecast before being passed to the query block or scope.
As an example:

```ruby
class PostSearch < TalentScout::ModelSearch
  criteria :created_on, :date do |date|
    where(created_at: date.beginning_of_day..date.end_of_day)
  end
end

PostSearch.new(created_on: "Dec 31, 1999")
```

Here, the string `"Dec 31, 1999"` passed to the `PostSearch` constructor
is typecast to a `Date` before being passed to the query block.

The default criteria type is `:string`, which means, by default, all
input values will be cast to strings.  This default (as opposed to a
default of no typecasting) ensures consistent behavior no matter how the
search object is constructed, whether from strongly-typed values or from
search form request params.

Available criteria types are the same as for Active Model attributes:
`:big_integer`, `:boolean`, `:date`, `:datetime`, `:decimal`, `:float`,
`:integer`, `:string`, `:time`, plus any custom types you define.

An additional convenience type is also available: `:void`.  The `:void`
type typecasts like `:boolean`, but prevents the criteria from being
applied when the typecasted value is falsey.  For example:

```ruby
class PostSearch < TalentScout::ModelSearch
  criteria :only_edited, :void do
    where("modified_at > created_at")
  end
end

# The following will apply `only_edited`:
PostSearch.new(only_edited: true)
PostSearch.new(only_edited: "1")

# The following will skip `only_edited`:
PostSearch.new(only_edited: false)
PostSearch.new(only_edited: "0")
PostSearch.new(only_edited: "")
```


#### Criteria Choices

Instead of specifying a type, a criteria definition may specify choices.
Choices define a set of values which can be passed to the query block.

Choices can either be specified as an Array of human-friendly values:

```ruby
class PostSearch < TalentScout::ModelSearch
  criteria :category, choices: %w[Science Tech Engineering Math] do |name|
    where(category: name.downcase)
  end
end
```

...Or as a Hash with human-friendly keys:

```ruby
class PostSearch < TalentScout::ModelSearch
  criteria :within, choices: {
    "Last 24 hours" => 24.hours,
    "Past Week" => 1.week,
    "Past Month" => 1.month,
    "Past Year" => 1.year,
  } do |duration|
    where("created_at >= ?", duration.ago)
  end
end
```

The value passed to the query block will be one of the values in the
Array or one of the values in the Hash.  The search object may be
constructed with any of the Array values or Hash keys or Hash values:

```ruby
PostSearch.new(category: "Math")
PostSearch.new(within: "Last 24 hours")
PostSearch.new(within: 24.hours)
```

But if an invalid choice is specified, the corresponding criteria will
not be applied:

```ruby
# The following will skip the criteria, but will not raise an error:
PostSearch.new(category: "Marketing")
PostSearch.new(within: 12.hours)
```


#### Criteria Default Value

A criteria definition can specify a default value, which will be passed
to the query block when the input value is missing.  Default values will
also appear in search forms.

```ruby
class PostSearch < TalentScout::ModelSearch
  criteria :within_days, :integer, default: 7 do |num|
    where("created_at >= ?", num.days.ago)
  end
end

# The following are equivalent:
PostSearch.new()
PostSearch.new(within_days: 7)
```


#### Criteria Resolution

A criteria will not be applied if any of the following are true:

* The criteria input value is missing, and no default value has been
  specified.

* The search object was constructed with an `ActionController::Parameters`
  (instead of a Hash), and the criteria input value is `blank?`, and no
  default value has been specified.  (This behavior prevents empty
  search form fields from affecting search results.)

* The typecast of the criteria input value fails.  For example:

  ```ruby
  class PostSearch < TalentScout::ModelSearch
    criteria :created_on, :date do |date|
      where(created_at: date.beginning_of_day..date.end_of_day)
    end
  end

  # The following will skip `created_on`, but will not raise an error:
  PostSearch.new(created_on: "BAD")
  ```

* The criteria definition specifies type `:void`, and the typecasted
  input value is falsey.

* The criteria definition specifies choices, and the input value is not
  a valid choice.

* The criteria query block returns `nil`.  For example:

  ```ruby
  class PostSearch < TalentScout::ModelSearch
    criteria :minimum_upvotes, :integer do |minimum|
      where("upvotes >= ?", minimum) unless minimum <= 0
    end
  end

  # The following will skip the `minimum_upvotes` where clause:
  PostSearch.new(minimum_upvotes: 0)
  ```


### Orders

Search result orders are defined with the `ModelSearch::order` method:

```ruby
class PostSearch < TalentScout::ModelSearch
  order :created_at
  order :title
  order :category
end

PostSearch.new(order: :created_at)
PostSearch.new(order: :title)
PostSearch.new(order: :category)
```

Only one order can be applied at a time, but an order can comprise
multiple columns:

```ruby
class PostSearch < TalentScout::ModelSearch
  order :category, [:category, :title]
end

# The following will order by "category, title":
PostSearch.new(order: :category)
```

This restricted design was chosen because it allows curated multi-column
sorts with simpler single-column sorting UIs, and because it prevents
ad-hoc multi-column sorts that may not be backed by a database index.


#### Order Direction

An order can be applied in ascending or descending direction.  The
`ModelSearch#toggle_order` method will apply an order in ascending
direction, or will change an applied order direction from ascending to
descending:

```ruby
class PostSearch < TalentScout::ModelSearch
  order :created_at
  order :title
end

# The following will order by "title":
PostSearch.new().toggle_order(:title)
PostSearch.new(order: :created_at).toggle_order(:title)

# The following will order by "title DESC":
PostSearch.new(order: :title).toggle_order(:title)
```

Note that the `toggle_order` method does not modify the existing search
object.  Instead, it builds a new search object with the new order and
the criteria values of the previous search object.

When a multi-column order is applied in descending direction, all
columns are affected:

```ruby
class PostSearch < TalentScout::ModelSearch
  order :category, [:category, :title]
end

# The following will order by "category DESC, title DESC":
PostSearch.new(order: :category).toggle_order(:category)
```

To circumvent this behavior and instead fix a column in a static
direction, append `" ASC"` or `" DESC"` to the column name:

```ruby
class PostSearch < TalentScout::ModelSearch
  order :category, [:category, "created_at ASC"]
end

# The following will order by "category, created_at ASC":
PostSearch.new(order: :category)

# The following will order by "category DESC, created_at ASC":
PostSearch.new(order: :category).toggle_order(:category)
```


#### Order Direction Suffixes

An order can be applied in ascending or descending direction directly,
without using `toggle_order`, by appending an appropriate suffix:

```ruby
class PostSearch < TalentScout::ModelSearch
  order :title
end

# The following will order by "title":
PostSearch.new(order: :title)
PostSearch.new(order: "title.asc")

# The following will order by "title DESC":
PostSearch.new(order: "title.desc")
```

The default suffixes, as seen in the above example, are `".asc"` and
`".desc"`.  These were chosen for their I18n-friendliness.  They can be
overridden as part of the order definition:

```ruby
class PostSearch < TalentScout::ModelSearch
  order "Title", [:title], asc_suffix: " (A-Z)", desc_suffix: " (Z-A)"
end

# The following will order by "title":
PostSearch.new(order: "Title")
PostSearch.new(order: "Title (A-Z)")

# The following will order by "title DESC":
PostSearch.new(order: "Title (Z-A)")
```


#### Default Order

An order can be designated as the default order, which will cause that
order to be applied when no order is otherwise specified:

```ruby
class PostSearch < TalentScout::ModelSearch
  order :created_at, default: :desc
  order :title
end

# The following will order by "created_at DESC":
PostSearch.new()

# The following will order by "created_at":
PostSearch.new(order: :created_at)

# The following will order by "title":
PostSearch.new(order: :title)
```

Note that the default order direction can be either ascending or
descending by specifing `default: :asc` or `default: :desc`,
respectively.  Also, just as only one order can be applied at a time,
only one order can be designated default.


### Default Scope

A default search scope can be defined with `ModelSearch::default_scope`:

```ruby
class PostSearch < TalentScout::ModelSearch
  default_scope { where(published: true) }
end
```

The default scope will be applied regardless of the criteria or order
input values.


## Controllers

Controllers can use the `model_search` helper method to construct a
search object with the current request's query params:

```ruby
class PostsController < ApplicationController
  def index
    @search = model_search
    @posts = @search.results
  end
end
```

In the above example, `model_search` constructs a `PostSearch` object.
The model search class is automatically derived from the controller
class name.  To override the model search class, use `::model_search_class=`:

```ruby
class EmployeesController < ApplicationController
  self.model_search_class = PersonSearch

  def index
    @search = model_search # will construct PersonSearch instead of `EmployeeSearch`
    @employees = @search.results
  end
end
```

In these examples, the search object is stored in `@search` for use in
the view.  Note that `@search.results` returns an `ActiveRecord::Relation`,
so any additional scoping, such as pagination, can be applied.


## Search Forms

Search forms can be rendered using Rails' form builder and a search
object:

```html+erb
<%= form_with model: @search, local: true, method: :get do |form| %>
  <%= form.label :title_includes %>
  <%= form.text_field :title_includes %>

  <%= form.label :created_on %>
  <%= form.date_field :created_on %>

  <%= form.label :only_published %>
  <%= form.check_box :only_published %>

  <%= form.submit %>
<% end %>
```

**Notice the `method: :get` argument to `form_with`.  This is required.**

Form fields will be populated with the criteria input (or default)
values of the same name from `@search`.  Type-appropriate form fields
can be used, e.g. `date_field` for type `:date`, `check_box` for types
`:boolean` and `:void`, etc.

By default, the form will submit to the index action of the controller
that corresponds to the `model_class` of the search object.  For
example, `PostSearch.model_class` is `Post`, so a form with an instance
of `PostSearch` will submit to `PostsController#index`.  To change where
the form submits to, use the `:url` option of `form_with`.


## Search Links

Search links can be rendered using the `link_to_search` view helper
method:

```html+erb
<%= link_to_search "Sort by title", @search.toggle_order(:title, :asc) %>
```

The link will automatically point to the current controller and current
action, with query parameters from the given search object.  To link to
a different controller or action, pass an options Hash in place of the
search object:

```html+erb
<%= link_to_search "Sort by title", { controller: "posts", action: "index",
      search: @search.toggle_order(:title, :asc) } %>
```

The `link_to_search` helper also accepts the same HTML options that
Rails' `link_to` helper does:

```html+erb
<%= link_to_search "Sort by title", @search.toggle_order(:title, :asc),
      id: "title-sort-link", class: "sort-link" %>
```

...As well as a content block:

```html+erb
<%= link_to_search @search.toggle_order(:title, :asc) do %>
  Sort by title <%= img_tag "sort_icon.png" %>
<% end %>
```


## `ModelSearch` Helper Methods

The `ModelSearch` class provides several methods that are helpful when
rendering the view.

One such method is `ModelSearch#toggle_order`, which was shown in
[previous examples](#order-direction).  Remember that `toggle_order` is
a builder-style method that does not modify the search object.  Instead,
it duplicates the search object, and sets the order on the new object.
Such behavior is suitable to generating links to multiple variants of a
search, such as sort links in table column headers.


### `ModelSearch#with` and `ModelSearch#without`

Two additional builder-style methods are `ModelSearch#with` and
`ModelSearch#without`.  Like `toggle_order`, both of these methods
return a new search object, leaving the original search object
unmodified.  The `with` method accepts a Hash of criteria input values
to merge on top of the original set of criteria input values:

```ruby
class PostSearch < TalentScout::ModelSearch
  criteria :title
  criteria :published, :boolean
end

# The following are equivalent:
PostSearch.new(title: "Maaaaath!", published: true)
PostSearch.new(title: "Maaaaath!").with(published: true)
PostSearch.new(title: "Math?").with(title: "Maaaaath!", published: true)
```

The `without` method accepts a list of criteria input values to exclude
(default criteria values still apply):

```ruby
class PostSearch < TalentScout::ModelSearch
  criteria :title
  criteria :published, :boolean, default: true
end

# The following are equivalent:
PostSearch.new(title: "Maaaaath!")
PostSearch.new(title: "Maaaaath!", published: false).without(:published)
```


### `ModelSearch#each_choice`

Another helpful method is `ModelSearch#each_choice`, which will iterate
over the defined choices for a given criteria.  This can be used to
generate links to variants of a search:

```ruby
class PostSearch < TalentScout::ModelSearch
  criteria :category, choices: %w[Science Tech Engineering Math]
end
```

```html+erb
<% @search.each_choice(:category) do |choice, chosen| %>
  <%= link_to_search "Category: #{choice}", @search.with(category: choice),
        class: ("active" if chosen) %>
<% end %>
```

Notice that if the block passed to `each_choice` accepts two arguments,
the 2nd argument will indicate if the choice is currently chosen.

If no block is passed to `each_choice`, it will return an `Enumerator`.
This can be used to generate options for a select box:

```html+erb
<%= form_with model: @search, local: true, method: :get do |form| %>
  <%= form.select :category, @search.each_choice(:category) %>
  <%= form.submit %>
<% end %>
```

The `each_choice` method can also be invoked with `:order`.  Doing so
will iterate over each direction of each defined order, yielding the
appropriate labels including direction suffix:

```ruby
class PostSearch < TalentScout::ModelSearch
  order "Title", [:title], asc_suffix: " (A-Z)", desc_suffix: " (Z-A)"
  order "Time", [:created_at], asc_suffix: " (oldest first)", desc_suffix: " (newest first)"
end
```

```html+erb
<%= form_with model: @search, local: true, method: :get do |form| %>
  <%= form.select :order, @search.each_choice(:order) %>
  <%= form.submit %>
<% end %>
```

The select box in the above form will list four options: "Title (A-Z)",
"Title (Z-A)", "Time (oldest first)", "Time (newest first)".


### `ModelSearch#order_directions`

Finally, the `ModelSearch#order_directions` helper method returns a
`HashWithIndifferentAccess` reflecting the currently applied direction
of each defined order.  It contains a key for each defined order, and
associates each key with either `:asc`, `:desc`, or `nil`.

```ruby
class PostSearch < TalentScout::ModelSearch
  order "Title", [:title]
  order "Time", [:created_at]
end
```

```html+erb
<thead>
  <tr>
    <% @search.order_directions.each do |order, direction| %>
      <th>
        <%= link_to_search order, @search.toggle_order(order) %>
        <%= img_tag "#{direction || "unsorted"}_icon.png" %>
      </th>
    <% end %>
  </tr>
</thead>
```

Remember that only one order can be applied at a time, so only one value
in the Hash, at most, will be non-`nil`.


## Installation

Add this line to your application's Gemfile:

```ruby
gem "talent_scout"
```

Then run:

```bash
$ bundle install
```

And finally, run the installation generator:

```bash
$ rails generate talent_scout:install
```


## Contributing

Run `rake test` to run the tests.


## License

[MIT License](MIT-LICENSE)
