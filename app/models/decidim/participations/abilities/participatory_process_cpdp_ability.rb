# frozen_string_literal: true

module Decidim
  module Participations
    module Abilities
      # Defines the abilities related to participations for a logged in process cpdp user.
      # Intended to be used with `cancancan`.
      class ParticipatoryProcessCpdpAbility < Decidim::Abilities::ParticipatoryProcessCpdpAbility

        def define_participatory_process_abilities
          super
          # Display functions and menu
          # See overwritten template app/views/layouts/decidim/admin/participatory_process.html.erb
          can [:manage, :read, :duplicate], Participation do |participation|
            can_manage_process?(participation.component.participatory_space)
          end

          can [:read, :manage], Feature do |component|
            component.manifest_name == "participations"
          end

          can [:unreport, :hide], Reportable do |reportable|
            can_manage_process?(reportable.component.participatory_space)
          end
        end
      end
    end
  end
end
