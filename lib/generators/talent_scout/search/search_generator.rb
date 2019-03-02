module TalentScout
  # @!visibility private
  module Generators
    class SearchGenerator < ::Rails::Generators::NamedBase
      source_root File.join(__dir__, "templates")
      hook_for :test_framework

      def generate_search
        template "search.rb",
          File.join("app/searches", class_path, "#{file_name}_search.rb")
      end
    end
  end
end
