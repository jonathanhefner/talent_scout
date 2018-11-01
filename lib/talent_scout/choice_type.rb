module TalentScout
  class ChoiceType < ActiveModel::Type::Value

    attr_reader :choices

    def initialize(mapping)
      @mapping = mapping.is_a?(Hash) ? mapping.stringify_keys : mapping.index_by(&:to_s)
      @choices = @mapping.keys.freeze

      if mapping.is_a?(Hash)
        @mapping.merge!(mapping) do |key, old_val, new_val|
          next old_val if old_val == new_val
          raise ArgumentError.new("Multiple possible values for key #{key.inspect}")
        end
      end

      @mapping.merge!(@mapping.values.index_by(&:itself)) do |key, old_val, new_val|
        next old_val if old_val == new_val
        raise ArgumentError.new("Value #{key.inspect} is also a key")
      end
    end

    def cast(value)
      super(@mapping[value])
    end

  end
end
