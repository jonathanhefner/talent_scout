module TalentScout
  class VoidType < ActiveModel::Type::Value

    MISSING = Object.new

    attr_reader :underlying_type

    def initialize
      @underlying_type = ActiveModel::Type.lookup(:boolean)
    end

    def cast(value)
      value = underlying_type.cast(value) unless MISSING == value
      super(value || MISSING)
    end

  end
end
