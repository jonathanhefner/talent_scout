module TalentScout
  class OrderType < ChoiceType

    attr_reader :definitions, :obverse_mapping

    def initialize()
      @definitions = ActiveSupport::HashWithIndifferentAccess.new
      @obverse_mapping = {}
      super({})
    end

    def initialize_copy(orig)
      super
      @definitions = @definitions.dup
      @obverse_mapping  = @obverse_mapping.dup
    end

    def cast(value)
      super(value) || definitions[value].try(&:asc_value)
    end

    def add_definition(definition)
      definitions[definition.name] = definition
      mapping[definition.asc_choice] = definition.asc_value
      mapping[definition.desc_choice] = definition.desc_value
      obverse_mapping[definition.asc_value] ||= { definition.name => :asc }
      obverse_mapping[definition.desc_value] ||= { definition.name => :desc }
    end

  end
end
