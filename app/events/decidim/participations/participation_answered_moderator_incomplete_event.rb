# frozen-string_literal: true

module Decidim
    module Participations
      class ParticipationAnsweredModeratorIncompleteEvent < Decidim::Events::BaseEvent
        include Decidim::Events::EmailEvent
        include Decidim::Events::NotificationEvent
   
        EVENT_NAME = "decidim.events.participation_answered_moderator_incomplete"
        
        def notification_title
            I18n.t(
              "#{EVENT_NAME}.notification_title",
              question_title: resource_title,
              action_url: action_url
            ).html_safe
        end
  
        def email_subject
          I18n.t("#{EVENT_NAME}.email_subject")
        end
  
        def email_greetings
          I18n.t(
            "#{EVENT_NAME}.email_greetings"
          ).html_safe
        end
  
        def email_intro
            I18n.t(
              "#{EVENT_NAME}.email_intro",
              question_title: resource_title,
              processus_participatif_title: extra[:participatory_process_title]
            )
          end
  
        def justification
          extra[:justification]
        end

        def action_url_name
          I18n.t("#{EVENT_NAME}.action_url_name")
        end
  
        def action_url
          admin_router_proxy.send("edit_participation_participation_answer_url", {id:resource.id, participation_id:resource.id})
        end

        private

        def admin_router_proxy
          admin_router_arg = resource.respond_to?(:feature) ? resource.feature : resource
          @admin_router_proxy ||= EngineRouter.admin_proxy(admin_router_arg)
        end
      end
    end
  end
  