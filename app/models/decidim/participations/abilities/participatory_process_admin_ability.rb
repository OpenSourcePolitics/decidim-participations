# frozen_string_literal: true

module Decidim
  module Participations
    module Abilities
      # Defines the abilities related to participations for a logged in process admin user.
      # Intended to be used with `cancancan`.
      class ParticipatoryProcessAdminAbility < Decidim::Abilities::ParticipatoryProcessAdminAbility
        def define_participatory_process_abilities
          super

          can [:manage, :unreport, :hide], Participation do |participation|
            can_manage_process?(participation.component.participatory_space)
          end

          cannot :create, Participation unless can_create_participation?
          cannot :update, Participation unless can_update_participation?
        end

        private

        def current_settings
          @context.fetch(:current_settings, nil)
        end

        def component_settings
          @context.fetch(:component_settings, nil)
        end

        def current_component
          @context.fetch(:current_component, nil)
        end

        def can_create_participation?
          current_settings.try(:creation_enabled?) &&
            component_settings.try(:official_participations_enabled) &&
            can_manage_process?(current_component.try(:participatory_space))
        end

        def can_update_participation?
          current_settings.try(:participation_answering_enabled) &&
            component_settings.try(:participation_answering_enabled)
        end
      end
    end
  end
end
