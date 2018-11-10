module TalentScout
  class ModelName < ActiveModel::Name

    PARAM_KEY = "q"

    def param_key
      PARAM_KEY
    end

    def route_key
      @klass.model.model_name.route_key
    end

    def singular_route_key
      @klass.model.model_name.singular_route_key
    end

  end
end
