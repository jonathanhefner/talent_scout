module TalentScout
  class Criteria

    attr_reader :names, :type, :block

    def initialize(names, type, &block)
      @names = Array(names).map(&:to_s)
      @type = case type
        when ActiveModel::Type::Value
          type
        when :void
          VoidType.new
        else
          ActiveRecord::Type.lookup(type)
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
end
