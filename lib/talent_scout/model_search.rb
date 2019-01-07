module TalentScout
  class ModelSearch
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment
    include ActiveRecord::AttributeMethods::BeforeTypeCast

    def self.model(model = nil)
      @model = model if model
      @model ||= self.superclass == ModelSearch ?
        self.name.chomp("Search").constantize : self.superclass.model
    end

    def self.model_name
      @model_name ||= ModelName.new(self)
    end

    def self.criteria(names, type = :string, choices: nil, **attribute_options, &block)
      if choices
        if type != :string
          raise ArgumentError.new("Option :choices cannot be used with type #{type}")
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
      self.criteria_list << crit

      crit.names.each do |name|
        attribute name, type, attribute_options

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

    def self.order(name, columns = nil, **options)
      unless attribute_types.fetch("order", nil).equal?(order_type)
        criteria_list.reject!{|crit| crit.names == ["order"] }
        criteria "order", order_type, &:order
      end

      order_type.add_definition(OrderDefinition.new(name, columns, options))
    end

    def initialize(params = {})
      if params.is_a?(ActionController::Parameters)
        params = params.permit(self.class.criteria_list.flat_map(&:names)).
          reject!{|k, v| v.blank? }
      end
      super(params)
    end

    def results(base_scope = self.class.model.all)
      self.class.criteria_list.reduce(base_scope) do |scope, crit|
        crit.apply(scope, attribute_set)
      end
    end

    def with(criteria_values)
      self.class.new(self.attributes.merge!(criteria_values.stringify_keys))
    end

    def without(*criteria_names)
      attributes = self.attributes
      criteria_names.map!(&:to_s)
      criteria_names.each do |name|
        raise ActiveModel::UnknownAttributeError.new(self, name) if !attributes.key?(name)
      end
      self.class.new(attributes.except!(*criteria_names))
    end

    def toggle_order(order_name, direction = nil)
      definition = self.class.order_type.definitions[order_name]
      raise ArgumentError.new("`#{order_name}` is not a valid order") unless definition
      direction ||= order_directions[order_name] == :asc ? :desc : :asc
      with(order: definition.choice_for_direction(direction))
    end

    def each_choice(criteria_name)
      criteria_name = criteria_name.to_s
      type = self.class.attribute_types.fetch(criteria_name, nil)
      unless type.is_a?(ChoiceType)
        raise ArgumentError.new("`#{criteria_name}` is not a criteria with choices")
      end
      return to_enum(:each_choice, criteria_name) unless block_given?

      type.mapping.each do |choice, value|
        chosen = value == attribute_set[criteria_name].value
        yield choice, chosen
      end
    end

    def order_directions
      @order_directions ||= begin
        order_after_cast = attribute_set.fetch("order", nil).try(&:value)
        self.class.order_type.definitions.transform_values{ nil }.
          merge!(self.class.order_type.obverse_mapping[order_after_cast] || {})
      end.freeze
    end

    def to_query_params
      attribute_set.values_before_type_cast.
        select{|key, value| attribute_set[key].changed? }
    end

    private

    def self.criteria_list
      @criteria_list ||= self == ModelSearch ? [] : self.superclass.criteria_list.dup
    end

    def self.order_type
      @order_type ||= self == ModelSearch ? OrderType.new : self.superclass.order_type.dup
    end

    def attribute_set
      @attributes # private instance variable from ActiveModel::Attributes ...YOLO!
    end

  end
end
