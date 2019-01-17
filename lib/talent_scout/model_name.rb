module TalentScout
  class ModelName < ActiveModel::Name

    def param_key
      TalentScout::PARAM_KEY
    end

    def route_key
      @klass.model_class.model_name.route_key
    end

    def singular_route_key
      @klass.model_class.model_name.singular_route_key
    end

  end
end
