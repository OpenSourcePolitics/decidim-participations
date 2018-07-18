# frozen_string_literal: true

module Decidim
  module Participations
    module Abilities
      # Defines the abilities related to participations for a logged in process moa user.
      # Intended to be used with `cancancan`.
      class ParticipatoryProcessMoaAbility < Decidim::Abilities::ParticipatoryProcessMoaAbility

        def define_participatory_process_abilities
          super

          # Display functions and menu
          # See overwritten template app/views/layouts/decidim/admin/participatory_process.html.erb

          can :read, ParticipatoryProcess do |process|
            can_manage_process?(process)
          end

          cannot :read, Moderation  do |moderation|
            can_manage_process?(moderation.participatory_space)
          end

          can [:update, :read], Participation do |participation|
            can_manage_process?(participation.component.participatory_space)
          end

          can [:manage, :read], Feature do |component|
            component.manifest_name == "participations"
          end
        end
      end
    end
  end
end
