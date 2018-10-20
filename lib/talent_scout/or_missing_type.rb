module TalentScout
  class OrMissingType < ActiveModel::Type::Value

    attr_reader :underlying_type, :missing

    def initialize(underlying_type, missing: nil)
      @underlying_type = underlying_type.is_a?(Symbol) ?
        ActiveModel::Type.lookup(underlying_type) : underlying_type
      @missing = missing
    end

    def cast(value)
      unless missing == value
        was_nil = value.nil?
        value = underlying_type.cast(value)
        # interpret nil as failed cast
        value = missing if !was_nil && value.nil?
      end
      super(value)
    end

  end
end
