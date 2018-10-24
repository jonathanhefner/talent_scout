module TalentScout
  class Railtie < ::Rails::Railtie
    initializer "talent_scout" do |app|
      ActiveSupport.on_load :action_controller do
        include TalentScout::Controller
      end
    end
  end
end
