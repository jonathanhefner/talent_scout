module TalentScout
  class ModelSearch
    include ActiveModel::Model
    include ActiveModel::Attributes

    def self.model(model = nil)
      @model = model if model
      @model ||= self.superclass == ModelSearch ?
        self.name.chomp("Search").constantize : self.superclass.model
    end

    def self.criteria(names, type = :string, default: nil, &block)
      crit = Criteria.new(names, type, &block)
      self.criteria_list << crit

      crit.names.each do |name|
        attribute name, crit.type, { default: default }.compact
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

    class Criteria
      attr_reader :names, :type, :block

      def initialize(names, type, &block)
        @names = Array(names).map(&:to_s)
        @type = case type
          when ActiveModel::Type::Value
            type
          when :void
            VoidType.new
          when Hash, Array
            ChoiceType.new(type)
          else
            ActiveModel::Type.lookup(type)
          end
        @block = block
      end

      def apply(scope, attribute_set)
        if applicable?(attribute_set)
          if block
            block_args = names.map{|name| attribute_set[name].value }
            if block.arity == -1 # block from Symbol#to_proc
              scope.instance_exec(scope, *block_args, &block)
            else
              scope.instance_exec(*block_args, &block)
            end || scope
          else
            where_args = names.reduce({}){|h, name| h[name] = attribute_set[name].value; h }
            scope.where(where_args)
          end
        else
          scope
        end
      end

      def applicable?(attribute_set)
        names.all? do |name|
          attribute = attribute_set[name]
          if attribute.came_from_user?
            if type.is_a?(TalentScout::VoidType)
              !attribute.value.nil?
            else
              !attribute.value.nil? || attribute.value_before_type_cast.nil?
            end
          end
        end
      end
    end

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
