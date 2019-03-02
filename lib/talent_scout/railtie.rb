module TalentScout
  # @!visibility private
  class Railtie < ::Rails::Railtie
    initializer "talent_scout" do |app|
      ActiveSupport.on_load :action_controller do
        include TalentScout::Controller
      end

      ActiveSupport.on_load :action_view do
        include TalentScout::Helper
      end
    end
  end
end
