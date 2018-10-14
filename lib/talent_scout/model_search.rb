module TalentScout
  class ModelSearch
    include ActiveModel::Model
    include ActiveModel::Attributes

    def self.criteria(names, type = :string)
      Array(names).each do |name|
        attribute name, type
      end
    end

  end
end
