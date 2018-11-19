module TalentScout
  class OrderType < ChoiceType

    attr_reader :orders

    def initialize()
      @orders = []
      super({})
    end

    def add_order(name, columns, **options)
      order = Order.new(name, columns, options)
      orders << order

      mapping[order.asc_name] = order.asc_value
      mapping[order.desc_name] = order.desc_value

      order
    end

  end
end
