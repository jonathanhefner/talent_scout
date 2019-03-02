module TalentScout
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      # Returns the controller model search class.  Defaults to a class
      # corresponding to the singular-form of the controller name.  The
      # model search class can also be set with {model_search_class=}.
      # If the model search class has not been set, and the default
      # class does not exist, a +NameError+ will be raised.
      #
      # @example
      #   class PostsController < ApplicationController
      #   end
      #
      #   PostsController.model_search_class  # == PostSearch (class)
      #
      # @return [Class<TalentScout::ModelSearch>]
      # @raise [NameError]
      #   if the model search class has not been set and the default
      #   class does not exist
      def model_search_class
        @model_search_class ||= "#{controller_path.classify}Search".constantize
      end

      # Sets the controller model search class.  See {model_search_class}.
      #
      # @param klass [Class<TalentScout::ModelSearch>]
      # @return [Class<TalentScout::ModelSearch>]
      def model_search_class=(klass)
        @model_search_class = klass
      end

      # Similar to {model_search_class}, but returns nil instead of
      # raising an error when the value has not been set (via
      # {model_search_class=}) and the default class does not exist.
      #
      # @return [Class<TalentScout::ModelSearch>, nil]
      def model_search_class?
        return @model_search_class if defined?(@model_search_class)
        begin
          model_search_class
        rescue NameError
          @model_search_class = nil
        end
      end
    end

    # Instantiates {ClassMethods#model_search_class} using the current
    # request's query params.  If that class does not exist, a
    # +NameError+ will be raised.
    #
    # @return [TalentScout::ModelSearch]
    # @raise [NameError]
    #   if the model search class does not exist
    def model_search()
      param_key = self.class.model_search_class.model_name.param_key
      self.class.model_search_class.new(params[param_key])
    end
  end
end
