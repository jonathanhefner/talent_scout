module TalentScout
  class OrMissingType < ActiveModel::Type::Value

    MISSING = Object.new

    attr_reader :underlying_type

    def initialize(underlying_type)
      @underlying_type = underlying_type.is_a?(Symbol) ?
        ActiveModel::Type.lookup(underlying_type) : underlying_type
    end

    def cast(value)
      unless MISSING == value
        was_nil = value.nil?
        value = underlying_type.cast(value)
        # interpret nil as failed cast
        value = MISSING if !was_nil && value.nil?
      end
      super(value)
    end

  end
end
