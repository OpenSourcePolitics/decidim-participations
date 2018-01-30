# frozen-string_literal: true

module Decidim
  module Participations
    class ParticipationModeratedEvent < Decidim::Events::BaseEvent
      include Decidim::Events::EmailEvent
      include Decidim::Events::NotificationEvent

      # Notification for Author

      def notification_title
        I18n.t(
          "decidim.events.participation_moderated.notification_title",
          processus_participatif_title: extra[:participatory_process_title],
          processus_participatif_url: processus_participatif_url
        ).html_safe
      end

      # Author email settings

      def email_greetings
        binding.pry
        I18n.t(
          "decidim.events.participation_moderated.email_greetings",
          author_name: participation.author.name
        ).html_safe
      end

      def email_intro
        I18n.t("decidim.events.participation_moderated.email_intro")
      end

      def action_url_name
        extra[:participatory_process_title]
      end

      def action_url
        processus_participatif_url
      end

      def email_outro
        I18n.t("decidim.events.participation_moderated.email_outro")
      end

      def email_subject
        I18n.t("decidim.events.participation_moderated.email_subject")
      end

      private

      def participation
        @participation ||= Decidim::Participations::Participation.find(resource.id)
      end

      def processus_participatif_url
        resource_locator.send("collection_route", "url", {host:participation.organization.host})
      end

    end
  end
end
