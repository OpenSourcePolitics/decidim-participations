# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin

          if create_permission_action?
            # There's no special condition to create participation notes, only
            # users with access to the admin section can do it.
            allow! if permission_action.subject == :participation_note

            # Participations can only be created from the admin when the
            # corresponding setting is enabled.
            toggle_allow(admin_creation_is_enabled?) if permission_action.subject == :participation

            # Participations can only be answered from the admin when the
            # corresponding setting is enabled.
            toggle_allow(admin_participation_answering_is_enabled?) if permission_action.subject == :participation_answer
          end

          # Every user allowed by the space can update the category of the participation
          allow! if permission_action.subject == :participation_category && permission_action.action == :update

          # Every user allowed by the space can import participations from another_component
          allow! if permission_action.subject == :participations && permission_action.action == :import

          permission_action
        end

        private

        def admin_creation_is_enabled?
          current_settings.try(:creation_enabled?) &&
            component_settings.try(:official_participations_enabled)
        end

        def admin_participation_answering_is_enabled?
          current_settings.try(:participation_answering_enabled) &&
            component_settings.try(:participation_answering_enabled)
        end

        # HERE WE MIGHT NEED TO DEFINE THE MOA & CPDP PERMISSION AT THE COMPONENT LEVEL

        def create_permission_action?
          permission_action.action == :create
        end

        def moa
      end
    end
  end
end
