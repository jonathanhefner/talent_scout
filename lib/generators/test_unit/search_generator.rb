# @!visibility private
module TestUnit
  module Generators
    class SearchGenerator < ::Rails::Generators::NamedBase
      source_root File.join(__dir__, "templates")

      def generate_test
        template "search_test.rb",
          File.join("test/searches", class_path, "#{file_name}_search_test.rb")
      end
    end
  end
end
