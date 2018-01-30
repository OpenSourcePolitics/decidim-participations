# frozen_string_literal: true

module Decidim
  module Participations
    module Abilities
      # Defines the abilities related to participations for a logged in process cpdp user.
      # Intended to be used with `cancancan`.
      class ParticipatoryProcessCpdpAbility < Decidim::Abilities::ParticipatoryProcessRoleAbility

        def role
          :cpdp
        end

        def define_participatory_process_abilities
          super
          # Display functions and menu
          # See overwritten template app/views/layouts/decidim/admin/participatory_process.html.erb
          can [:manage, :read, :duplicate], Participation do |participation|
            can_manage_process?(participation.feature.participatory_space)
          end

          can [:read, :manage], Feature do |feature|
            feature.manifest_name == "participations"
          end

          can [:unreport, :hide], Participation do |participation|
            can_manage_process?(participation.feature.participatory_space)
          end
        end
      end
    end
  end
end
