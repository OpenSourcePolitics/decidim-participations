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

          # Dispaly functions and menu
          # See overwritten template app/views/layouts/decidim/admin/participatory_process.html.erb
          can [:read], ParticipatoryProcess do |process|
            can_manage_process?(process)
          end

          can :manage, Moderation do |moderation|
            can_manage_process?(moderation.participatory_space)
          end

          cannot :read, Decidim::Moderation

          # Display functions and menu
          # See overwritten template app/views/layouts/decidim/admin/participatory_process.html.erb
          can :read, Feature do |feature|
            feature.manifest_name == "participations"
          end

          can [:read, :duplicate], Participation

          can :update, Participation do |participation|
            participation.moderation.upstream_moderation == "waiting_for_answer" ||participation.moderation.upstream_moderation == "accepted"
          end

          can [:unreport, :hide], Participation do |participation|
            can_manage_process?(participation.feature.participatory_space)
          end
        end
      end
    end
  end
end
