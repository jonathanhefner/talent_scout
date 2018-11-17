module TalentScout
  class ChoiceType < ActiveModel::Type::Value

    attr_reader :mapping

    def initialize(mapping)
      @mapping = if mapping.is_a?(Hash)
        unless mapping.all?{|k, v| k.is_a?(String) || k.is_a?(Symbol) }
          raise ArgumentError.new("Only String and Symbol keys are supported")
        end
        mapping.stringify_keys
      else
        mapping.index_by(&:to_s)
      end
    end

    def cast(value)
      key = value.to_s if value.is_a?(String) || value.is_a?(Symbol)
      if @mapping.key?(key)
        super(@mapping[key])
      elsif @mapping.value?(value)
        super(value)
      end
    end

  end
end
