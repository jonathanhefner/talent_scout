module TalentScout
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def model_search_class
        @model_search_class ||= "#{controller_path.classify}Search".constantize
      end

      def model_search_class=(klass)
        @model_search_class = klass
      end
    end

    def model_search(model_search_class = self.class.model_search_class)
      param_key = model_search_class.model_name.param_key
      model_search_class.new(params[param_key])
    end
  end
end
