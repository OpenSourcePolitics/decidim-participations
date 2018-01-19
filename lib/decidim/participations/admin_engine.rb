# frozen_string_literal: true

module Decidim
  module Participations
    # This is the engine that runs on the public interface of `decidim-participations`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Participations::Admin

      paths["db/migrate"] = nil

      routes do
        resources :participations, only: [:index, :new, :create] do
          post :copy, on: :member
          resources :participation_answers, only: [:edit, :update]
          
        end

        root to: "participations#index"
      end

      initializer "decidim_participations.inject_abilities_to_user" do |_app|
        Decidim.configure do |config|
          config.admin_abilities += [
            "Decidim::Participations::Abilities::AdminAbility",
            "Decidim::Participations::Abilities::ParticipatoryProcessAdminAbility",
            "Decidim::Participations::Abilities::ParticipatoryProcessModeratorAbility"
          ]
        end
      end

      def load_seed
        nil
      end
    end
  end
end
