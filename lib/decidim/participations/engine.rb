# frozen_string_literal: true

require "kaminari"
require "social-share-button"
require "ransack"

module Decidim
  module Participations
    # This is the engine that runs on the public interface of `decidim-participations`.
    # It mostly handles rendering the created page associated to a participatory
    # process.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Participations

      routes do
        resources :participations, except: [:destroy] do
          resource :participation_vote, only: [:create, :destroy]
          resource :participation_widget, only: :show, path: "embed"
        end
        root to: "participations#index"
      end

      initializer "decidim_participations.assets" do |app|
        app.config.assets.precompile += %w(decidim_participations_manifest.js decidim_participations_manifest.css)
      end

      initializer "decidim_participations.inject_abilities_to_user" do |_app|
        Decidim.configure do |config|
          config.abilities += ["Decidim::Participations::Abilities::CurrentUserAbility"]
        end
      end
    end
  end
end
