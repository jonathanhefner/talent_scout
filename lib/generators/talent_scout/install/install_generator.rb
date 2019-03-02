module TalentScout
  # @!visibility private
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      def copy_locales
        template "config/locales/talent_scout.en.yml",
          { param_key: TalentScout::PARAM_KEY }
      end
    end
  end
end
