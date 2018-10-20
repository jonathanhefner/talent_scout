module TalentScout
  class VoidType < ActiveModel::Type::Value

    attr_reader :underlying_type, :missing

    def initialize(missing: nil)
      @underlying_type = ActiveModel::Type.lookup(:boolean)
      @missing = missing
    end

    def cast(value)
      value = underlying_type.cast(value) unless missing == value
      super(value || missing)
    end

  end
end
