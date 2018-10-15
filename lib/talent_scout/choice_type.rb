module TalentScout
  class ChoiceType < ActiveModel::Type::Value

    attr_reader :choices

    def initialize(choices)
      @choices = choices.stringify_keys
    end

    def cast(value)
      super(@choices[value.to_s])
    end

  end
end
