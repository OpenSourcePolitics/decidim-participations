# frozen_string_literal: true

module Decidim
  module Participations
    module Abilities
      # Defines the abilities related to participations for a logged in process moderator user.
      # Intended to be used with `cancancan`.
      class ParticipatoryProcessModeratorAbility < Decidim::Abilities::ParticipatoryProcessModeratorAbility
        def define_participatory_process_abilities
          super

          # Dispaly functions and menu
          # See overwritten template app/views/layouts/decidim/admin/participatory_process.html.erb
          can [:manage, :read, :update, :preview], Component do |component|
            component.manifest_name == "participations"
          end

          can [:manage, :read, :duplicate], Participation do |participation|
            can_manage_process?(participation.component.participatory_space)
          end
        end
      end
    end
  end
end
