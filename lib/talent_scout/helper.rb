module TalentScout
  module Helper

    def link_to_search(name, search = nil, html_options = nil, &block)
      name, search, html_options = nil, name, search if block_given?

      if search.is_a?(Hash)
        url_options = search.dup
        search = url_options.delete(:search)
      else
        url_options = {}
      end

      raise ArgumentError.new("`search` cannot be nil") if search.nil?

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
