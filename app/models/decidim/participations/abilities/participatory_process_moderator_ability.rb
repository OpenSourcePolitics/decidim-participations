# frozen_string_literal: true

module Decidim
  module Participations
    module Abilities
      # Defines the abilities related to participations for a logged in process admin user.
      # Intended to be used with `cancancan`.
      class ParticipatoryProcessModeratorAbility < Decidim::Abilities::ParticipatoryProcessModeratorAbility
        def define_participatory_process_abilities
          super

          can [:unreport, :hide], Participation do |participation|
            can_manage_process?(participation.feature.participatory_space)
          end
        end
      end
    end
  end
end
