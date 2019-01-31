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

      def model_search_class?
        return @model_search_class if defined?(@model_search_class)
        begin
          model_search_class
        rescue NameError
          @model_search_class = nil
        end
      end
    end

    def model_search()
      param_key = self.class.model_search_class.model_name.param_key
      self.class.model_search_class.new(params[param_key])
    end
  end
end
