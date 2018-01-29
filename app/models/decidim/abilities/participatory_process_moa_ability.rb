# frozen_string_literal: true

module Decidim
  module Abilities
    # Defines the abilities for a participatory process moa. Intended to be
    # used with `cancancan`.
    # This ability will not apply to organization admins.
    class ParticipatoryProcessMoaAbility < ParticipatoryProcessRoleAbility
      # Overrides ParticipatoryProcessRoleAbility role method
      def role
        :moa
      end
    end
  end
end
