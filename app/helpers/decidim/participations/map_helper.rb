# frozen_string_literal: true

module Decidim
  module Participations
    # This helper include some methods for rendering participations dynamic maps.
    module MapHelper
      # Serialize a collection of geocoded participations to be used by the dynamic map component
      #
      # geocoded_participations - A collection of geocoded participations
      def participations_data_for_map(geocoded_participations)
        geocoded_participations.map do |participation|
          participation.slice(:latitude, :longitude, :address).merge(title: participation.title,
                                                                body: truncate(strip_tags(participation.body), length: 100),
                                                                icon: icon("participations", width: 40, height: 70, remove_icon_class: true),
                                                                link: participation_path(participation))
        end
      end
    end
  end
end
