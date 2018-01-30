# frozen_string_literal: true

module Decidim
  module Participations
    # This is the engine that runs on the public interface of `decidim-participations`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Participations::Admin

      paths["db/migrate"] = nil

      routes do
        resources :participations do
          resources :copy_participations, only: [:create]
          resources :participation_answers, only: [:edit, :update]

        end

        resources :moderation, only: [:update]

        root to: "participations#index"
      end

      initializer "decidim_participations.inject_abilities_to_user" do |_app|
        Decidim.configure do |config|
          config.admin_abilities += [
            "Decidim::Participations::Abilities::AdminAbility",
            "Decidim::Participations::Abilities::ParticipatoryProcessAdminAbility",
            "Decidim::Participations::Abilities::ParticipatoryProcessModeratorAbility",
            "Decidim::Participations::Abilities::ParticipatoryProcessMoaAbility",
            "Decidim::Participations::Abilities::ParticipatoryProcessCpdpAbility"
          ]
        end
      end

      initializer "decidim.inject_abilities_to_user" do |_app|
        Decidim.configure do |config|
          config.abilities << "Decidim::Abilities::ParticipatoryProcessCpdpAbility"
          config.abilities << "Decidim::Abilities::ParticipatoryProcessMoaAbility"
        end
      end

      initializer "decidim_participatory_processes.inject_abilities_to_user" do |_app|
        Decidim.configure do |config|
          config.admin_abilities += [
            "Decidim::ParticipatoryProcesses::Abilities::Admin::ParticipatoryProcessCpdpAbility",
            "Decidim::ParticipatoryProcesses::Abilities::Admin::ParticipatoryProcessMoaAbility"
          ]
        end
      end



      def load_seed
        nil
      end
    end
  end
end
