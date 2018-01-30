# frozen-string_literal: true

module Decidim
  module Participations
    class ParticipationCreatedEventModeration < Decidim::Events::BaseEvent
      include Decidim::Events::EmailEvent
      include Decidim::Events::NotificationEvent

      # Notification for Author

      def notification_title
        I18n.t(
          "decidim.events.participation_created.moderation.notification_title",
          processus_participatif_title: extra[:participatory_process_title],
          url: action_moderation_url
        ).html_safe
      end

      # Moderation email settings

      def email_moderation_subject
        I18n.t(
          "decidim.events.participation_created.moderation.email_subject",
          processus_participatif_title: extra[:participatory_process_title]
        ).html_safe
      end

      def email_moderation_intro
        I18n.t(
          "decidim.events.participation_created.moderation.email_intro",
          processus_participatif_title: extra[:participatory_process_title],
          author_name: participation.author.name
        ).html_safe
      end

      def action_moderation_url_name
        I18n.t(
          "decidim.events.participation_created.moderation.action_url_name"
        ).html_safe
      end

      def action_moderation_url
        admin_router_proxy.send("edit_participation_url", {id:resource.id})
      end

      private

      def participation
        @participation ||= Decidim::Participations::Participation.find(resource.id)
      end

      def admin_router_proxy
        admin_router_arg = resource.respond_to?(:feature) ? resource.feature : resource
        @admin_router_proxy ||= EngineRouter.admin_proxy(admin_router_arg)
      end
    end
  end
end
