module TalentScout
  module Helper

    # Renders an anchor element that links to a specified search.  The
    # search is specified in the form of a {TalentScout::ModelSearch}
    # search object, which is converted to URL query params.  By
    # default, the link will point to the current controller and current
    # action, but this can be overridden by passing a +search_options+
    # Hash in place of the search object (see method overloads).
    #
    # @overload link_to_search(name, search, html_options = nil)
    #   @param name [String]
    #     link text
    #   @param search [TalentScout::ModelSearch]
    #     search object
    #   @param html_options [Hash, nil]
    #     HTML options (see +ActionView::Helpers::UrlHelper#link_to+)
    #
    # @overload link_to_search(search, html_options = nil, &block)
    #   @param search [TalentScout::ModelSearch]
    #     search object
    #   @param html_options [Hash, nil]
    #     HTML options (see +ActionView::Helpers::UrlHelper#link_to+)
    #   @yieldreturn [String]
    #     link text
    #
    # @overload link_to_search(name, search_options, html_options = nil)
    #   @param name [String]
    #     link text
    #   @param search_options [Hash]
    #     search options
    #   @option search_options :search [TalentScout::ModelSearch]
    #     search object
    #   @option search_options :controller [String, nil]
    #     controller to link to (defaults to current controller)
    #   @option search_options :action [String, nil]
    #     controller action to link to (defaults to current action)
    #   @param html_options [Hash, nil]
    #     HTML options (see +ActionView::Helpers::UrlHelper#link_to+)
    #
    # @overload link_to_search(search_options, html_options = nil, &block)
    #   @param search_options [Hash]
    #     search options
    #   @option search_options :search [TalentScout::ModelSearch]
    #     search object
    #   @option search_options :controller [String, nil]
    #     controller to link to (defaults to current controller)
    #   @option search_options :action [String, nil]
    #     controller action to link to (defaults to current action)
    #   @param html_options [Hash, nil]
    #     HTML options (see +ActionView::Helpers::UrlHelper#link_to+)
    #   @yieldreturn [String]
    #     link text
    #
    # @return [String]
    # @raise [ArgumentError]
    #   if +search+ or <code>search_options[:search]</code> is nil
    def link_to_search(name, search = nil, html_options = nil, &block)
      name, search, html_options = nil, name, search if block_given?

      if search.is_a?(Hash)
        url_options = search.dup
        search = url_options.delete(:search)
      else
        url_options = {}
      end

      raise ArgumentError, "`search` cannot be nil" if search.nil?

      url_options[:controller] ||= controller_path
      url_options[:action] ||= action_name
      url_options[search.model_name.param_key] = search.to_query_params

      if block_given?
        link_to(url_options, html_options, &block)
      else
        link_to(name, url_options, html_options)
      end
    end

  end
end
