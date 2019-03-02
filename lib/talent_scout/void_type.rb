module TalentScout
  # @!visibility private
  class VoidType < ActiveModel::Type::Value

    attr_reader :underlying_type

    def initialize
      @underlying_type = ActiveModel::Type.lookup(:boolean)
    end

    def cast(value)
      super(underlying_type.cast(value) || nil)
    end

  end
end
