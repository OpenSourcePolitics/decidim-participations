# frozen_string_literal: true

require "decidim/participations/admin"
require "decidim/participations/engine"
require "decidim/participations/admin_engine"
require "decidim/participations/feature"

module Decidim
  # This namespace holds the logic of the `Participations` component. This component
  # allows users to create participations in a participatory process.
  module Participations
    autoload :ParticipationSerializer, "decidim/participations/participation_serializer"
  end
end
