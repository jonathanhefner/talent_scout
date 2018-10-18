module TalentScout
  class ModelSearch
    include ActiveModel::Model
    include ActiveModel::Attributes

    def self.model
      @model ||= self.name.chomp("Search").constantize
    end

    def self.criteria(names, type = :string, &block)
      crit = Criteria.new(names, type, &block)

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

      def initialize(names, type, &block)
        @names = Array(names).map(&:to_s)
        @type = OrMissingType.new(type.is_a?(Hash) ? ChoiceType.new(type) : type)
        @default = OrMissingType::MISSING
        @block = block
      end

      def apply(scope, attributes)
        block_args = names.map{|name| attributes[name] }
        if block_args.none?{|value| OrMissingType::MISSING == value }
          scope.instance_exec(*block_args, &block)
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
