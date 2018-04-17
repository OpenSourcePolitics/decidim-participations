# frozen_string_literal: true

module Decidim
  module Participations
    # This class serializes a Participation so can be exported to CSV, JSON or other
    # formats.
    class ParticipationSerializer < Decidim::Exporters::Serializer
      include Decidim::ResourceHelper

      # Public: Initializes the serializer with a participation.
      def initialize(participation)
        @participation = participation
      end

      # Public: Exports a hash with the serialized data for this participation.
      def serialize
        {
          id: @participation.id,
          category: {
            id: @participation.category.try(:id),
            name: @participation.category.try(:name)
          },
          scope: {
            id: @participation.scope.try(:id),
            name: @participation.scope.try(:name)
          },
          title: @participation.title,
          body: strip_body,
          votes: @participation.participation_votes_count,
          comments: @participation.comments.count,
          created_at: @participation.created_at,
          url: url,
          feature: { id: feature.id },
          meeting_urls: meetings
        }
      end

      private

      attr_reader :participation

      def strip_body
        ActionView::Base.full_sanitizer.sanitize(@participation.body)
      end

      def feature
        participation.feature
      end

      def meetings
        @participation.linked_resources(:meetings, "participations_from_meeting").map do |meeting|
          Decidim::ResourceLocatorPresenter.new(meeting).url
        end
      end

      def url
        Decidim::ResourceLocatorPresenter.new(participation).url
      end
    end
  end
end
