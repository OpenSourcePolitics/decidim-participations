# frozen-string_literal: true

module Decidim
    module Participations
      class ModerateMoaResponseEvent < Decidim::Events::BaseEvent
        include Decidim::Events::EmailEvent
        include Decidim::Events::NotificationEvent
   
        def notification_title
          I18n.t(
            "decidim.events.moderate_moa_response.notification_title",
            url: action_url
          ).html_safe
        end
  
        def email_subject
          I18n.t("decidim.events.moderate_moa_response.email_subject")
        end
  
        def email_greetings
          I18n.t(
            "decidim.events.moderate_moa_response.email_greetings",
          ).html_safe
        end
  
        def email_intro
            I18n.t(
              "decidim.events.moderate_moa_response.email_intro",
              question_title: resource_title,
              processus_participatif_title: extra[:participatory_process_title]
            )
          end
  
  
        def action_url_name
          I18n.t("decidim.events.moderate_moa_response.action_url_name")
        end
  
        def action_url
          # TODO http://localhost:3000/admin/participatory_processes/debitis-voluptates/features/14/manage/participations
          processus_participatif_url
        end
  
        private
  
        def processus_participatif_url
          resource_locator.send("collection_route", "url", {host:participation.organization.host})
        end
  
      end
    end
  end
  