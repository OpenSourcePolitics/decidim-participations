# frozen_string_literal: true

module Decidim
  module Abilities
    # Defines the abilities for a participatory process cpdp. Intended to be
    # used with `cancancan`.
    # This ability will not apply to organization admins.
    class ParticipatoryProcessCpdpAbility < ParticipatoryProcessRoleAbility
      # Overrides ParticipatoryProcessRoleAbility role method
      def role
        :cpdp
      end
    end
  end
end
