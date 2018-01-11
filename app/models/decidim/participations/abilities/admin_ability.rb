# frozen_string_literal: true

module Decidim
  module Participations
    module Abilities
      # Defines the abilities related to participations for a logged in admin user.
      # Intended to be used with `cancancan`.
      class AdminAbility < Decidim::Abilities::AdminAbility
        def define_abilities
          super

          can :manage, Participation
          can :unreport, Participation
          can :hide, Participation
          cannot :create, Participation unless can_create_participation?
          cannot :update, Participation unless can_update_participation?
        end

        private

        def current_settings
          @context.fetch(:current_settings, nil)
        end

        def feature_settings
          @context.fetch(:feature_settings, nil)
        end

        def can_create_participation?
          current_settings.try(:creation_enabled?) &&
            feature_settings.try(:official_participations_enabled)
        end

        def can_update_participation?
          current_settings.try(:participation_answering_enabled) &&
            feature_settings.try(:participation_answering_enabled)
        end
      end
    end
  end
end
