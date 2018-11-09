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

    def self.criteria(names, type = :string, default: nil, &block)
      crit = Criteria.new(names, type, &block)
      self.criteria_list << crit

      crit.names.each do |name|
        attribute name, crit.type, { default: default }.compact

        # HACK FormBuilder#select uses normal attribute readers instead
        # of `*_before_type_cast` attribute readers.  This breaks value
        # auto-selection for types where the two are appreciably
        # different, e.g. ChoiceType with hash mapping.  Work around by
        # aliasing relevant attribute readers to `*_before_type_cast`.
        if crit.type.is_a?(ChoiceType)
          alias_method name, "#{name}_before_type_cast"
        end

        self.criteria_by_name[name] = crit
      end
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

    def choices_for(criteria_name)
      crit = self.class.criteria_by_name[criteria_name.to_s]
      if crit && crit.type.is_a?(ChoiceType)
        crit.type.choices
      else
        raise ArgumentError.new("`#{criteria_name}` is not a criteria with choices")
      end
    end

    private

    def self.criteria_list
      @criteria_list ||= self == ModelSearch ? [] : self.superclass.criteria_list.dup
    end

    def self.criteria_by_name
      @criteria_by_name ||= self.superclass == ModelSearch ?
        {} : self.superclass.criteria_by_name.dup
    end

    def attribute_set
      @attributes # private instance variable from ActiveModel::Attributes ...YOLO!
    end

  end
end
