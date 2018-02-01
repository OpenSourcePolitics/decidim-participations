# frozen-string_literal: true

module Decidim
    module Participations
      class ParticipationAnsweredAuthorEvent < Decidim::Events::BaseEvent
        include Decidim::Events::EmailEvent
        include Decidim::Events::NotificationEvent
   
        EVENT_NAME = "decidim.events.participation_answered_author"
        
        def notification_title
            I18n.t(
              "#{EVENT_NAME}.notification_title",
              processus_participatif_title: extra[:participatory_process_title],
              action_url: action_url
            ).html_safe
          end
  
        def email_subject
          I18n.t(
              "#{EVENT_NAME}.email_subject",
              processus_participatif_title: extra[:participatory_process_title]
              )
        end
  
        def email_greetings
          I18n.t(
            "#{EVENT_NAME}.email_greetings",
            author_name: participation.author.name
          ).html_safe
        end
  
        def email_intro
            I18n.t(
              "#{EVENT_NAME}.email_intro",
              processus_participatif_title: extra[:participatory_process_title]
            )
          end
  
  
        def action_url_name
          I18n.t("#{EVENT_NAME}.action_url_name")
        end
  
        def action_url
          resource_url
        end
      end
    end
  end
  