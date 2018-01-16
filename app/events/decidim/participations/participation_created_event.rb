# frozen-string_literal: true

module Decidim
  module Participations
    class ParticipationCreatedEvent < Decidim::Events::BaseEvent
      include Decidim::Events::EmailEvent
      include Decidim::Events::NotificationEvent

      def notification_title
        I18n.t(
          "decidim.events.participation_created.notification_title",
          resource_title: resource_title,
          resource_path: resource_locator.path,
          author_name: participation.author.name
        ).html_safe
      end

      def email_url
        I18n.t(
          "decidim.events.participation_created.url",
          resource_url: resource_locator.url
        ).html_safe
      end

      def email_subject
        I18n.t(
          "decidim.events.participation_created.email_subject",
          author_name: participation.author.name
        ).html_safe
      end

      def email_moderation_intro
        I18n.t(
          "decidim.events.participation_created.moderation.email_intro",
          resource_title: resource_title,
          author_name: participation.author.name
        ).html_safe
      end

      def email_moderation_subject
        I18n.t(
          "decidim.events.participation_created.moderation.email_subject",
          resource_title: resource_title,
          resource_url: resource_locator.url,
          author_name: participation.author.name
        ).html_safe
      end

      def email_moderation_url(moderation_url)
        I18n.t(
          "decidim.events.participation_created.moderation.moderation_url",
          moderation_url: moderation_url
        ).html_safe
      end

      private

      def participation
        @participation ||= Decidim::Participations::Participation.find(resource.id)
      end
    end
  end
end
