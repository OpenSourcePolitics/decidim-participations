module Decidim
  module Participations
      class NewParticipationQuestionEvent < Decidim::Events::BaseEvent
        include Decidim::Events::EmailEvent
        include Decidim::Events::NotificationEvent
        include Rails.application.routes.url_helpers

        def email_subject
          I18n.t(
            "decidim.events.new_participation_question_event.email_subject",
            processus_participatif_title: extra[:participatory_process_title]
          )
        end

        def email_greeting
          I18n.t("decidim.events.new_participation_question_event.email_greetings")
        end

        def email_intro
          I18n.t(
            "decidim.events.new_participation_question_event.email_intro",
            question_title: resource_title,
            processus_participatif_title: extra[:participatory_process_title]
          )
        end

        def action_url
          admin_router_proxy.send("edit_participation_participation_answer_url", {id:resource.id, participation_id:resource.id})
        end

        def action_url_name
          I18n.t("decidim.events.new_participation_question_event.action_url_name")
        end

        def notification_title
          I18n.t(
            "decidim.events.new_participation_question_event.notification_title",
            processus_participatif_title: extra[:participatory_process_title],
            action_url: action_url
          ).html_safe
        end

        private

        def admin_router_proxy
          admin_router_arg = resource.respond_to?(:component) ? resource.component : resource
          @admin_router_proxy ||= EngineRouter.admin_proxy(admin_router_arg)
        end

      end
    end
  end

