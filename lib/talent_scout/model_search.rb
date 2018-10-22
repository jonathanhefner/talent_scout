module TalentScout
  class ModelSearch
    include ActiveModel::Model
    include ActiveModel::Attributes

    MISSING_VALUE = Object.new

    def self.model(model = nil)
      @model = model if model
      @model ||= self.name.chomp("Search").constantize
    end

    def self.criteria(names, type = :string, default: MISSING_VALUE, &block)
      crit = Criteria.new(names, type, default, &block)

      crit.names.each do |name|
        attribute name, crit.type, default: crit.default
      end

      self.criteria_list << crit
    end

    def results
      attributes = self.attributes
      self.class.criteria_list.reduce(self.class.model.all) do |scope, crit|
        crit.apply(scope, attributes)
      end
    end

    private

    class Criteria
      attr_reader :names, :type, :default, :block

      def initialize(names, type, default, &block)
        @names = Array(names).map(&:to_s)
        @type = case type
          when :void
            VoidType.new(missing: MISSING_VALUE)
          when Hash, Array
            OrMissingType.new(ChoiceType.new(type), missing: MISSING_VALUE)
          else
            OrMissingType.new(type, missing: MISSING_VALUE)
          end
        @default = default
        @block = block
      end

      def apply(scope, attributes)
        if names.none?{|name| MISSING_VALUE == attributes[name] }
          if block
            block_args = attributes.values_at(*names)
            if block.arity == -1 # block from Symbol#to_proc
              scope.instance_exec(scope, *block_args, &block)
            else
              scope.instance_exec(*block_args, &block)
            end || scope
          else
            scope.where(attributes.slice(*names))
          end
        else
          scope
        end
      end
    end

    def self.criteria_list
      @criteria_list ||= []
    end

  end
end
