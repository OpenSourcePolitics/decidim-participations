# frozen_string_literal: true

module Decidim
  module Participations
    module Abilities
      # Defines the abilities related to participations for a logged in process moa user.
      # Intended to be used with `cancancan`.
      class ParticipatoryProcessMoaAbility < Decidim::Abilities::ParticipatoryProcessRoleAbility

        def role
          :moa
        end

        def define_participatory_process_abilities
          super

          # Display functions and menu
          # See overwritten template app/views/layouts/decidim/admin/participatory_process.html.erb
          can [:read], ParticipatoryProcess do |process|
            can_manage_process?(process)
          end

          # Display functions and menu
          # See overwritten template app/views/layouts/decidim/admin/participatory_process.html.erb
          can :read, Feature do |feature|
            feature.manifest_name == "participations"
          end

          can [:read], Participation

          can :update, Participation do |participation|
            participation.moderation.upstream_moderation == "waiting_for_answer" ||participation.moderation.upstream_moderation == "accepted"
          end
        end
      end
    end
  end
end
