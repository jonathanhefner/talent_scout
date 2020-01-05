module TalentScout
  class ModelSearch
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment
    include ActiveRecord::AttributeMethods::BeforeTypeCast
    extend ActiveModel::Translation

    # Returns the model class that the search targets.  Defaults to a
    # class with same name name as the search class, minus the "Search"
    # suffix.  The model class can also be set with {model_class=}.
    # If the model class has not been set, and the default class does
    # not exist, a +NameError+ will be raised.
    #
    # @example Default behavior
    #   class PostSearch < TalentScout::ModelSearch
    #   end
    #
    #   PostSearch.model_class  # == Post (class)
    #
    # @example Override
    #   class EmployeeSearch < TalentScout::ModelSearch
    #     self.model_class = Person
    #   end
    #
    #   EmployeeSearch.model_class  # == Person (class)
    #
    # @return [Class]
    # @raise [NameError]
    #   if the model class has not been set and the default class does
    #   not exist
    def self.model_class
      @model_class ||= self.superclass == ModelSearch ?
        self.name.chomp("Search").constantize : self.superclass.model_class
    end

    # Sets the model class that the search targets.  See {model_class}.
    #
    # @param model_class [Class]
    # @return [Class]
    def self.model_class=(model_class)
      @model_class = model_class
    end

    # @!visibility private
    def self.model_name
      @model_name ||= ModelName.new(self)
    end

    # Sets the default scope of the search.  Like Active Record's
    # +default_scope+, the scope here is specified as a block which is
    # evaluated in the context of the {model_class}.  Also like
    # Active Record, multiple calls of this method will append to the
    # default scope.
    #
    # @example
    #   class PostSearch < TalentScout::ModelSearch
    #     default_scope { where(published: true) }
    #   end
    #
    #   PostSearch.new.results  # == Post.where(published: true)
    #
    # @example Using an existing scope
    #   class Post < ActiveRecord::Base
    #     scope :published, ->{ where(published: true) }
    #   end
    #
    #   class PostSearch < TalentScout::ModelSearch
    #     default_scope(&:published)
    #   end
    #
    #   PostSearch.new.results  # == Post.published
    #
    # @yieldreturn [ActiveRecord::Relation]
    # @return [void]
    def self.default_scope(&block)
      i = criteria_list.index{|crit| !crit.names.empty? } || -1
      criteria_list.insert(i, Criteria.new([], true, &block))
    end

    # Defines criteria to incorporate into the search.  Each criteria
    # corresponds to an attribute on the search object that can be used
    # when building a search form.
    #
    # Each attribute has a type, just as Active Model attributes do, and
    # values passed into the search object are typecasted before
    # criteria are evaluated.  Supported types are the same as Active
    # Model (e.g. +:string+, +:boolean+, +:integer+, etc), with the
    # addition of a +:void+ type.  A +:void+ type is just like a
    # +:boolean+ type, except that the criteria is not evaluated when
    # the typecasted value is falsey.
    #
    # Alternatively, instead of a type, an Array or Hash of +choices+
    # can be specified, and the criteria will be evaluated only if the
    # passed-in value matches one of the choices.
    #
    # Active Model +attribute_options+ can also be specified.  Most
    # notably, the +:default+ option provides the criteria a default
    # value to operate on.
    #
    # Each criteria can specify a block which recieves its corresponding
    # typecasted value as an argument.  If the corresponding value is
    # not set on the search object, and no default value is defined,
    # the criteria will not be evaluated.  Like an Active Record
    # +scope+ block, a criteria block is evaluated in the context of an
    # +ActiveRecord::Relation+, and should return an
    # +ActiveRecord::Relation+.  A criteria block may also return nil,
    # in which case the criteria will be skipped.  If no criteria block
    # is specified, the criteria will be evaluated as a +where+ clause
    # using the criteria name and typecasted value.
    #
    # As a convenient shorthand, Active Record scopes which have been
    # defined on the {model_class} can be used directly as criteria
    # blocks by passing the scope's name as a symbol-to-proc in place of
    # the criteria block.
    #
    #
    # @example Implicit block
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :title
    #   end
    #
    #   PostSearch.new(title: "FOO").results  # == Post.where(title: "FOO")
    #
    #
    # @example Explicit block
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :title do |string|
    #       where("title LIKE ?", "%#{string}%")
    #     end
    #   end
    #
    #   PostSearch.new(title: "FOO").results  # == Post.where("title LIKE ?", "%FOO%")
    #
    #
    # @example Using an existing Active Record scope
    #   class Post < ActiveRecord::Base
    #     scope :title_includes, ->(string){ where("title LIKE ?", "%#{string}%") }
    #   end
    #
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :title, &:title_includes
    #   end
    #
    #   PostSearch.new(title: "FOO").results  # == Post.title_includes("FOO")
    #
    #
    # @example Specifying a type
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :created_on, :date do |date|
    #       where(created_at: date.beginning_of_day..date.end_of_day)
    #     end
    #   end
    #
    #   PostSearch.new(created_on: "Dec 31, 1999").results
    #     # == Post.where(created_at: Date.new(1999, 12, 31).beginning_of_day..
    #     #                           Date.new(1999, 12, 31).end_of_day)
    #
    #
    # @example Using the void type
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :only_edited, :void do
    #       where("modified_at > created_at")
    #     end
    #   end
    #
    #   PostSearch.new(only_edited: false).results  # == Post.all
    #   PostSearch.new(only_edited: "0").results    # == Post.all
    #   PostSearch.new(only_edited: "").results     # == Post.all
    #   PostSearch.new(only_edited: true).results   # == Post.where("modified_at > created_at")
    #   PostSearch.new(only_edited: "1").results    # == Post.where("modified_at > created_at")
    #
    #
    # @example Specifying choices (Array)
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :category, choices: %w[science tech engineering math]
    #   end
    #
    #   PostSearch.new(category: "math").results  # == Post.where(category: "math")
    #   PostSearch.new(category: "BLAH").results  # == Post.all
    #
    #
    # @example Specifying choices (Hash)
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :within, choices: {
    #       "Last 24 hours" => 24.hours,
    #       "Past Week" => 1.week,
    #       "Past Month" => 1.month,
    #       "Past Year" => 1.year,
    #     } do |duration|
    #       where("created_at >= ?", duration.ago)
    #     end
    #   end
    #
    #   PostSearch.new(within: "Last 24 hours").results  # == Post.where("created_at >= ?", 24.hours.ago)
    #   PostSearch.new(within: 24.hours).results         # == Post.where("created_at >= ?", 24.hours.ago)
    #   PostSearch.new(within: 23.hours).results         # == Post.all
    #
    #
    #
    # @example Specifying a default value
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :within_days, :integer, default: 7 do |num|
    #       where("created_at >= ?", num.days.ago)
    #     end
    #   end
    #
    #   PostSearch.new().results                # == Post.where("created_at >= ?", 7.days.ago)
    #   PostSearch.new(within_days: 2).results  # == Post.where("created_at >= ?", 2.days.ago)
    #
    #
    # @overload criteria(names, type = :string, **attribute_options, &block)
    #   @param names [String, Symbol, Array<String>, Array<Symbol>]
    #   @param type [Symbol, ActiveModel::Type]
    #   @param attribute_options [Hash]
    #   @option attribute_options :default [Object]
    #   @yieldparam value [Object]
    #   @yieldreturn [ActiveRecord::Relation, nil]
    #
    # @overload criteria(names, type = :string, **attribute_options)
    #   @param names [String, Symbol, Array<String>, Array<Symbol>]
    #   @param type [Symbol, ActiveModel::Type]
    #   @param attribute_options [Hash]
    #   @option attribute_options :default [Object]
    #
    # @overload criteria(names, choices:, **attribute_options, &block)
    #   @param names [String, Symbol, Array<String>, Array<Symbol>]
    #   @param choices [Array<String>, Array<Symbol>, Hash<String, Object>, Hash<Symbol, Object>]
    #   @param attribute_options [Hash]
    #   @option attribute_options :default [Object]
    #   @yieldparam value [Object]
    #   @yieldreturn [ActiveRecord::Relation, nil]
    #
    # @overload criteria(names, choices:, **attribute_options)
    #   @param names [String, Symbol, Array<String>, Array<Symbol>]
    #   @param choices [Array<String>, Array<Symbol>, Hash<String, Object>, Hash<Symbol, Object>]
    #   @param attribute_options [Hash]
    #   @option attribute_options :default [Object]
    #   @yieldreturn [ActiveRecord::Relation, nil]
    #
    # @return [void]
    # @raise [ArgumentError]
    #   if +choices+ is specified and +type+ is not +:string+
    def self.criteria(names, type = :string, choices: nil, **attribute_options, &block)
      if choices
        if type != :string
          raise ArgumentError, "Option :choices cannot be used with type #{type}"
        end
        type = ChoiceType.new(choices)
      elsif type == :void
        type = VoidType.new
      elsif type.is_a?(Symbol)
        # HACK force ActiveRecord::Type.lookup because datetime types
        # from ActiveModel::Type.lookup don't support multi-parameter
        # attribute assignment
        type = ActiveRecord::Type.lookup(type)
      end

      crit = Criteria.new(names, !type.is_a?(VoidType), &block)
      criteria_list << crit

      crit.names.each do |name|
        attribute name, type, **attribute_options

        # HACK FormBuilder#select uses normal attribute readers instead
        # of `*_before_type_cast` attribute readers.  This breaks value
        # auto-selection for types where the two are appreciably
        # different, e.g. ChoiceType with hash mapping.  Work around by
        # aliasing relevant attribute readers to `*_before_type_cast`.
        if type.is_a?(ChoiceType)
          alias_method name, "#{name}_before_type_cast"
        end
      end
    end

    # Defines an order that the search can apply to its results.  Only
    # one order can be applied at a time, but an order can be defined
    # over multiple columns.  If no columns are specified, the order's
    # +name+ is taken as its column.
    #
    # Each order can be applied in an ascending or descending direction
    # by appending a corresponding suffix to the order value.  By
    # default, these suffixes are +".asc"+ and +".desc"+, but they can
    # be overridden in the order definition using the +:asc_suffix+ and
    # +:desc_suffix+ options, respectively.
    #
    # Order direction affects all columns of an order defintion, unless
    # a column explicitly specifies +"ASC"+ or +"DESC"+, in which case
    # that column will stay fixed in its specified direction.
    #
    # To apply an order to the search results by default, use the
    # +:default+ option in the order definition.  (Note that only one
    # order can be designated as the default order.)
    #
    # @see toggle_order
    #
    #
    # @example Single-column order
    #   class PostSearch < TalentScout::ModelSearch
    #     order :title
    #   end
    #
    #   PostSearch.new(order: :title).results        # == Post.order("title")
    #   PostSearch.new(order: "title.asc").results   # == Post.order("title")
    #   PostSearch.new(order: "title.desc").results  # == Post.order("title DESC")
    #
    #
    # @example Multi-column order
    #   class PostSearch < TalentScout::ModelSearch
    #     order :category, [:category, :title]
    #   end
    #
    #   PostSearch.new(order: :category).results        # == Post.order("category, title")
    #   PostSearch.new(order: "category.asc").results   # == Post.order("category, title")
    #   PostSearch.new(order: "category.desc").results  # == Post.order("category DESC, title DESC")
    #
    #
    # @example Multi-column order, fixed directions
    #   class PostSearch < TalentScout::ModelSearch
    #     order :category, ["category", "title ASC", "created_at DESC"]
    #   end
    #
    #   PostSearch.new(order: :category).results
    #     # == Post.order("category, title ASC, created_at DESC")
    #   PostSearch.new(order: "category.asc").results
    #     # == Post.order("category, title ASC, created_at DESC")
    #   PostSearch.new(order: "category.desc").results
    #     # == Post.order("category DESC, title ASC, created_at DESC")
    #
    #
    # @example Specifying direction suffixes
    #   class PostSearch < TalentScout::ModelSearch
    #     order "Title", [:title], asc_suffix: " (A-Z)", desc_suffix: " (Z-A)"
    #   end
    #
    #   PostSearch.new(order: "Title").results        # == Post.order("title")
    #   PostSearch.new(order: "Title (A-Z)").results  # == Post.order("title")
    #   PostSearch.new(order: "Title (Z-A)").results  # == Post.order("title DESC")
    #
    #
    # @example Default order
    #   class PostSearch < TalentScout::ModelSearch
    #     order :created_at, default: :desc
    #     order :title
    #   end
    #
    #   PostSearch.new().results                         # == Post.order("created_at DESC")
    #   PostSearch.new(order: :created_at).results       # == Post.order("created_at")
    #   PostSearch.new(order: "created_at.asc").results  # == Post.order("created_at")
    #   PostSearch.new(order: :title).results            # == Post.order("title")
    #
    #
    # @param name [String, Symbol]
    # @param columns [Array<String>, Array<Symbol>, nil]
    # @param options [Hash]
    # @option options :default [Boolean, :asc, :desc] (false)
    # @option options :asc_suffix [String] (".asc")
    # @option options :desc_suffix [String] (".desc")
    # @return [void]
    def self.order(name, columns = nil, default: false, **options)
      definition = OrderDefinition.new(name, columns, **options)

      if !attribute_types.fetch("order", nil).equal?(order_type) || default
        criteria_options = default ? { default: definition.choice_for_direction(default) } : {}
        criteria_list.reject!{|crit| crit.names == ["order"] }
        criteria "order", order_type, **criteria_options, &:order
      end

      order_type.add_definition(definition)
    end

    # Initializes a +ModelSearch+ instance.  Assigns values from
    # +params+ to corresponding criteria attributes.
    #
    # If +params+ is a +ActionController::Parameters+, blank values are
    # ignored.  This behavior prevents empty search form fields from
    # affecting search results.
    #
    # @param params [Hash<String, Object>, Hash<Symbol, Object>, ActionController::Parameters]
    # @raise [ActiveModel::UnknownAttributeError]
    #   if +params+ is a Hash, and it contains an unrecognized key
    def initialize(params = {})
      # HACK initialize ActiveRecord state required by ActiveRecord::AttributeMethods::BeforeTypeCast
      @transaction_state ||= nil

      if params.is_a?(ActionController::Parameters)
        params = params.permit(self.class.attribute_types.keys).reject!{|key, value| value.blank? }
      end
      super(params)
    end

    # Applies the {default_scope}, search {criteria} with set or default
    # attribute values, and the set or default {order} to the
    # {model_class}.  Returns an +ActiveRecord::Relation+, allowing
    # further scopes, such as pagination, to be applied post-hoc.
    #
    # @example
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :title
    #     criteria :category
    #     criteria :published, :boolean, default: true
    #
    #     order :created_at, default: :desc
    #     order :title
    #   end
    #
    #   PostSearch.new(title: "FOO").results
    #     # == Post.where(title: "FOO", published: true).order("created_at DESC")
    #   PostSearch.new(category: "math", order: :title).results
    #     # == Post.where(category: "math", published: true).order("title")
    #
    # @return [ActiveRecord::Relation]
    def results
      self.class.criteria_list.reduce(self.class.model_class.all) do |scope, crit|
        crit.apply(scope, attribute_set)
      end
    end

    # Builds a new model search object with +criteria_values+ merged on
    # top of the subject search object's criteria values.
    #
    # Does not modify the subject search object.
    #
    # @example
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :title
    #     criteria :category
    #   end
    #
    #   search = PostSearch.new(category: "math")
    #
    #   search.with(title: "FOO").results      # == Post.where(category: "math", title: "FOO")
    #   search.with(category: "tech").results  # == Post.where(category: "tech")
    #   search.results                         # == Post.where(category: "math")
    #
    # @param criteria_values [Hash<String, Object>, Hash<Symbol, Object>]
    # @return [TalentScout::ModelSearch]
    # @raise [ActiveModel::UnknownAttributeError]
    #   if one or more +criteria_values+ keys are invalid
    def with(criteria_values)
      self.class.new(attributes.merge!(criteria_values.stringify_keys))
    end

    # Builds a new model search object with the subject search object's
    # criteria values, excluding values specified by +criteria_names+.
    # Default criteria values will still be applied.
    #
    # Does not modify the subject search object.
    #
    # @example
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :category
    #     criteria :published, :boolean, default: true
    #   end
    #
    #   search = PostSearch.new(category: "math", published: false)
    #
    #   search.without(:category).results   # == Post.where(published: false)
    #   search.without(:published).results  # == Post.where(category: "math", published: true)
    #   search.results                      # == Post.where(category: "math", published: false)
    #
    # @param criteria_names [Array<String>, Array<Symbol>]
    # @return [TalentScout::ModelSearch]
    # @raise [ActiveModel::UnknownAttributeError]
    #   if one or more +criteria_names+ are invalid
    def without(*criteria_names)
      criteria_names.map!(&:to_s)
      criteria_names.each do |name|
        raise ActiveModel::UnknownAttributeError.new(self, name) if !attribute_set.key?(name)
      end
      self.class.new(attributes.except!(*criteria_names))
    end

    # Builds a new model search object with the specified order applied
    # on top of the subject search object's criteria values.  If the
    # subject search object already has the specified order applied, the
    # order's direction will be toggled from +:asc+ to +:desc+ or from
    # +:desc+ to +:asc+.  Otherwise, the specified order will be applied
    # with an +:asc+ direction, overriding any previously applied order.
    #
    # If +direction+ is explicitly specified, that direction will be
    # applied regardless of previously applied direction.
    #
    # Does not modify the subject search object.
    #
    # @example
    #   class PostSearch < TalentScout::ModelSearch
    #     order :title
    #     order :created_at
    #   end
    #
    #   search = PostSearch.new(order: :title)
    #
    #   search.toggle_order(:title).results       # == Post.order("title DESC")
    #   search.toggle_order(:created_at).results  # == Post.order("created_at")
    #   search.results                            # == Post.order("title")
    #
    # @param order_name [String, Symbol]
    # @param direction [:asc, :desc, nil]
    # @return [TalentScout::ModelSearch]
    # @raise [ArgumentError]
    #   if +order_name+ is invalid
    def toggle_order(order_name, direction = nil)
      definition = self.class.order_type.definitions[order_name]
      raise ArgumentError, "`#{order_name}` is not a valid order" unless definition
      direction ||= order_directions[order_name] == :asc ? :desc : :asc
      with(order: definition.choice_for_direction(direction))
    end

    # Iterates over a specified {criteria}'s defined choices.  If the
    # given block accepts a 2nd argument, a boolean will be passed
    # indicating whether that choice is currently assigned to the
    # specified criteria.
    #
    # An Enumerator is returned if no block is given.
    #
    # @example With block
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :category, choices: %w[science tech engineering math]
    #   end
    #
    #   search = PostSearch.new(category: "math")
    #
    #   search.each_choice(:category) do |choice, chosen|
    #     puts "<li class=\"#{'active' if chosen}\">#{choice}</li>"
    #   end
    #
    #
    # @example Without block
    #   class PostSearch < TalentScout::ModelSearch
    #     criteria :category, choices: %w[science tech engineering math]
    #   end
    #
    #   search = PostSearch.new(category: "math")
    #
    #   search.each_choice(:category).to_a
    #     # == ["science", "tech", "engineering", "math"]
    #
    #   search.each_choice(:category).map do |choice, chosen|
    #     chosen ? "<b>#{choice}</b>" : choice
    #   end
    #     # == ["science", "tech", "engineering", "<b>math</b>"]
    #
    #
    # @overload each_choice(criteria_name, &block)
    #   @param criteria_name [String, Symbol]
    #   @yieldparam choice [String]
    #   @return [void]
    #
    # @overload each_choice(criteria_name, &block)
    #   @param criteria_name [String, Symbol]
    #   @yieldparam choice [String]
    #   @yieldparam chosen [Boolean]
    #   @return [void]
    #
    # @overload each_choice(criteria_name)
    #   @param criteria_name [String, Symbol]
    #   @return [Enumerator]
    #
    # @raise [ArgumentError]
    #   if +criteria_name+ is invalid, or the specified criteria does
    #   not define choices
    def each_choice(criteria_name, &block)
      criteria_name = criteria_name.to_s
      type = self.class.attribute_types.fetch(criteria_name, nil)
      unless type.is_a?(ChoiceType)
        raise ArgumentError, "`#{criteria_name}` is not a criteria with choices"
      end
      return to_enum(:each_choice, criteria_name) unless block

      value_after_cast = attribute_set[criteria_name].value
      type.mapping.each do |choice, value|
        chosen = value_after_cast.equal?(value)
        block.arity >= 2 ? block.call(choice, chosen) : block.call(choice)
      end
    end

    # Returns a +HashWithIndifferentAccess+ with a key for each defined
    # {order}.  Each key's associated value indicates that order's
    # currently applied direction -- +:asc+, +:desc+, or +nil+ if the
    # order is not applied.  Note that only one order can be applied at
    # a time, so, at most, one value in the Hash will be non-+nil+.
    #
    # @example
    #   class PostSearch < TalentScout::ModelSearch
    #     order :title
    #     order :created_at
    #   end
    #
    #   PostSearch.new(order: "title").order_directions       # == { title: :asc, created_at: nil }
    #   PostSearch.new(order: "title DESC").order_directions  # == { title: :desc, created_at: nil }
    #   PostSearch.new(order: "created_at").order_directions  # == { title: nil, created_at: :asc }
    #   PostSearch.new().order_directions                     # == { title: nil, created_at: nil }
    #
    # @return [ActiveSupport::HashWithIndifferentAccess]
    def order_directions
      @order_directions ||= begin
        order_after_cast = attribute_set.fetch("order", nil).try(&:value)
        self.class.order_type.definitions.transform_values{ nil }.
          merge!(self.class.order_type.obverse_mapping[order_after_cast] || {})
      end.freeze
    end

    # @!visibility private
    def to_query_params
      attribute_set.values_before_type_cast.
        select{|key, value| attribute_set[key].changed? }
    end

    # @!visibility private
    # HACK Implemented by ActiveRecord but not ActiveModel.  Expected by
    # some third-party form builders, e.g. Simple Form.
    def has_attribute?(name)
      self.class.attribute_types.key?(name.to_s)
    end

    # @!visibility private
    # HACK Implemented by ActiveRecord but not ActiveModel.  Expected by
    # some third-party form builders, e.g. Simple Form.
    def type_for_attribute(name)
      self.class.attribute_types[name.to_s]
    end

    private

    # @!visibility private
    def self.criteria_list
      @criteria_list ||= self == ModelSearch ? [] : self.superclass.criteria_list.dup
    end

    # @!visibility private
    def self.order_type
      @order_type ||= self == ModelSearch ? OrderType.new : self.superclass.order_type.dup
    end

    def attribute_set
      @attributes # private instance variable from ActiveModel::Attributes ...YOLO!
    end

  end
end
