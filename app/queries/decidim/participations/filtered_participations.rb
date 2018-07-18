# frozen_string_literal: true

module Decidim
  module Participations
    # A class used to find participations filtered by components and a date range
    class FilteredParticipations < Rectify::Query
      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - An array of Decidim::Feature
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      def self.for(components, start_at = nil, end_at = nil)
        new(components, start_at, end_at).query
      end

      # Initializes the class.
      #
      # components - An array of Decidim::Feature
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      def initialize(components, start_at = nil, end_at = nil)
        @components = components
        @start_at = start_at
        @end_at = end_at
      end

      # Finds the Participations scoped to an array of components and filtered
      # by a range of dates.
      def query
        participations = Decidim::Participations::Participation.where(component: @components)
        participations = participations.where("created_at >= ?", @start_at) if @start_at.present?
        participations = participations.where("created_at <= ?", @end_at) if @end_at.present?
        participations
      end
    end
  end
end
