module TalentScout
  class Order

    DEFAULT_ASC_SUFFIX = ""
    DEFAULT_DESC_SUFFIX = "_desc"

    attr_reader :base_name, :asc_name, :desc_name, :asc_value, :desc_value

    def initialize(name, columns, asc_suffix: DEFAULT_ASC_SUFFIX, desc_suffix: DEFAULT_DESC_SUFFIX)
      columns = Array(columns || name)
      @base_name = name.to_s
      @asc_value = Arel.sql(columns.join(", "))
      @desc_value = Arel.sql(Order.desc(columns).join(", "))
      @asc_name = "#{@base_name}#{asc_suffix}"
      @desc_name = @desc_value == @asc_value ? @asc_name : "#{@base_name}#{desc_suffix}"
    end

    def self.desc(columns)
      columns.map do |column|
        column.match?(/ (?:ASC|DESC)$/i) ? column : "#{column} DESC"
      end
    end

  end
end
