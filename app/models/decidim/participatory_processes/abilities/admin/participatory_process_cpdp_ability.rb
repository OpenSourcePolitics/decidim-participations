# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    module Abilities
      module Admin
        # Defines the abilities for a user in the admin section. Intended to be
        # used with `cancancan`.
        class ParticipatoryProcessCpdpAbility < Decidim::Abilities::ParticipatoryProcessCpdpAbility
          def define_abilities
            super
            can :read, ParticipatoryProcess do |process|
              can_manage_process?(process)
            end

            can :manage, Moderation do |moderation|
              can_manage_process?(moderation.participatory_space)
            end
          end
        end
      end
    end
  end
end
