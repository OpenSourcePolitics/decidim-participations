# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    module Abilities
      module Admin
        # Defines the abilities for a user in the admin section. Intended to be
        # used with `cancancan`.
        class ParticipatoryProcessMoaAbility < Decidim::Abilities::ParticipatoryProcessCpdpAbility
          def define_abilities
            super

          can [:read], ParticipatoryProcess do |process|
            can_manage_process?(process)
          end

          can [:update, :read], Participation do |participation|
            can_manage_process?(participation.feature.participatory_space)
          end

          can [:read, :manage], Feature do |feature|
            feature.manifest_name == "participations"
          end
        end
      end
    end
  end
end
