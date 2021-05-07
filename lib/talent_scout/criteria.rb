module TalentScout
  # @!visibility private
  class Criteria
    SYMBOL_TO_PROC_ARITY = :to_s.to_proc.arity

    attr_reader :names, :allow_nil, :block

    def initialize(names, allow_nil, &block)
      @names = Array(names).map(&:to_s)
      @allow_nil = allow_nil
      @block = block
    end

    def apply(scope, attribute_set)
      if applicable?(attribute_set)
        if block
          block_args = names.map{|name| attribute_set[name].value }
          if block.arity == SYMBOL_TO_PROC_ARITY # assume block is from Symbol#to_proc
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
        attribute.came_from_user? &&
          (!attribute.value.nil? || (allow_nil && attribute.value_before_type_cast.nil?))
      end
    end

  end
end
