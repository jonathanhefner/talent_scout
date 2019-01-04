module TalentScout
  class OrderType < ChoiceType

    attr_reader :orders

    def initialize()
      @orders = ActiveSupport::HashWithIndifferentAccess.new
      super({})
    end

    def initialize_copy(orig)
      super
      @orders = @orders.dup
    end

    def cast(value)
      super(value) || orders[value].try(&:asc_value)
    end

    def add_order(name, columns, **options)
      order = Order.new(name, columns, options)
      orders[order.name] = order
      mapping[order.asc_choice] = order.asc_value
      mapping[order.desc_choice] = order.desc_value
      order
    end

  end
end
