# frozen-string_literal: true

module Decidim
  module Participations
    class ParticipationModeratedEvent < Decidim::Events::BaseEvent
      include Decidim::Events::EmailEvent
      include Decidim::Events::NotificationEvent

      # Notification for Author

      def notification_title
        I18n.t(
          "decidim.events.participation_moderated.#{extra[:state]}.notification_title",
          processus_participatif_title: extra[:participatory_process_title],
          processus_participatif_url: processus_participatif_url
        ).html_safe
      end

      def email_subject
        I18n.t("decidim.events.participation_moderated.#{extra[:state]}.email_subject",
          processus_participatif_title: extra[:participatory_process_title]
        )
      end

      def email_greetings
        I18n.t(
          "decidim.events.participation_moderated.#{extra[:state]}.email_greetings",
          author_name: participation.author.name
        ).html_safe
      end

      def email_intro
        I18n.t("decidim.events.participation_moderated.#{extra[:state]}.email_intro",
          processus_participatif_title: extra[:participatory_process_title],
          justification: extra[:justification]
        )
      end

      def action_url_name
        extra[:participatory_process_title]
      end

      def action_url
        processus_participatif_url
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
