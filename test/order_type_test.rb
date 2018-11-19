require "test_helper"
require "talent_scout"

class OrderTypeTest < Minitest::Test

  def test_order_type_is_choice_type
    type = TalentScout::OrderType.new
    assert_kind_of TalentScout::ChoiceType, type
  end

  def test_orders_after_add_order
    orders = make_orders(COLUMNS)
    type = make_type(COLUMNS)
    assert_equal orders.map(&:base_name), type.orders.map(&:base_name)
  end

  def test_mapping_after_add_order
    orders = make_orders(COLUMNS)
    type = make_type(COLUMNS)
    expected = orders.flat_map do |order|
      [[order.asc_name, order.asc_value], [order.desc_name, order.desc_value]]
    end
    assert_kind_of Hash, type.mapping
    assert_equal expected, type.mapping.to_a
  end

  private

  COLUMNS = ["col1", "col2", "col3"]

  def make_orders(columns)
    columns.map{|column| TalentScout::Order.new(column, [column]) }
  end

  def make_type(columns)
    TalentScout::OrderType.new.tap do |type|
      columns.each{|column| type.add_order(column, [column]) }
    end
  end

end
