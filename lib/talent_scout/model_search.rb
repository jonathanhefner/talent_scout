module TalentScout
  class ModelSearch
    include ActiveModel::Model
    include ActiveModel::Attributes

    def self.criteria(names, type = :string)
      type = ChoiceType.new(type) if type.is_a?(Hash)

      Array(names).each do |name|
        attribute name, type
      end
    end

  end
end
