module TalentScout
  class OrderType < ChoiceType

    attr_reader :definitions

    def initialize()
      @definitions = ActiveSupport::HashWithIndifferentAccess.new
      super({})
    end

    def initialize_copy(orig)
      super
      @definitions = @definitions.dup
    end

    def cast(value)
      super(value) || definitions[value].try(&:asc_value)
    end

    def add_definition(name, columns, **options)
      definition = OrderDefinition.new(name, columns, options)
      definitions[definition.name] = definition
      mapping[definition.asc_choice] = definition.asc_value
      mapping[definition.desc_choice] = definition.desc_value
      definition
    end

  end
end
