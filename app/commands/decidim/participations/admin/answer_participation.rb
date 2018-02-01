# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      # A command with all the business logic when an admin answers a participation.
      class AnswerParticipation < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # participation - The participation to write the answer for.
        # current_participatory_process - The current participatory process
        def initialize(form, participation, current_participatory_process)
          @form = form
          @participation = participation
          @current_participatory_process = current_participatory_process
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          answer_participation
          update_moderation
          send_notification_moderate_moa_response if @participation.waiting_for_validation?
          if @participation.question? 
            if @participation.authorized? 
              send_notification_participation_published_answer_author
              send_notification_participation_published_answer_moa 
            elsif @participation.incomplete?
              send_notification_participation_incomplete_answer_moa
            end
          end  

          broadcast(:ok)
        end

        private

        def send_notification_participation_incomplete_answer_moa
          moa_ids = Decidim::ParticipatoryProcessUserRole.where(decidim_participatory_process_id: @current_participatory_process.id).where("role IN (?)", ["moa"]).map(&:decidim_user_id)

          Decidim::EventsManager.publish(
            event: ParticipationAnsweredModeratorIncompleteEvent::EVENT_NAME,
            event_class: ParticipationAnsweredModeratorIncompleteEvent,
            resource: @participation,
            recipient_ids: moa_ids.uniq,
            extra: {
              template: "participation_answered_moderator_incomplete_event",
              participatory_process_title: participatory_process_title,
              justification: @form.moderation.justification

            }
          )
        end

        def send_notification_participation_published_answer_moa
          moa_ids = Decidim::ParticipatoryProcessUserRole.where(decidim_participatory_process_id: @current_participatory_process.id).where("role IN (?)", ["moa"]).map(&:decidim_user_id)

          Decidim::EventsManager.publish(
            event: ParticipationAnsweredModeratorPublishedEvent::EVENT_NAME,
            event_class: ParticipationAnsweredModeratorPublishedEvent,
            resource: @participation,
            recipient_ids: moa_ids.uniq,
            extra: {
              template: "participation_answered_moderator_published_event",
              participatory_process_title: participatory_process_title
            }
          )
        end

        def send_notification_participation_published_answer_author
          recipient_ids = [participation.author.id]

          Decidim::EventsManager.publish(
            event: ParticipationAnsweredAuthorEvent::EVENT_NAME,
            event_class: ParticipationAnsweredAuthorEvent,
            resource: @participation,
            recipient_ids: recipient_ids.uniq,
            extra: {
              template: "participation_answered_author_event",
              participatory_process_title: participatory_process_title
            }
          )
        end

        def send_notification_moderate_moa_response
          cpdp_moderators_ids = Decidim::ParticipatoryProcessUserRole.where(decidim_participatory_process_id: @current_participatory_process.id).where("role IN (?)", ["cpdp", "moderator"]).map(&:decidim_user_id)

          Decidim::EventsManager.publish(
            event: "decidim.events.moderate_moa_response",
            event_class: Decidim::Participations::ModerateMoaResponseEvent,
            resource: @participation,
            recipient_ids: cpdp_moderators_ids.uniq,
            extra: {
              template: "moderate_moa_response_event",
              participatory_process_title: participatory_process_title
            }
          )
        end

        attr_reader :form, :participation

        def participatory_process_title
          if @current_participatory_process.title.is_a?(Hash)
             @current_participatory_process.title[I18n.locale.to_s]
          else
            @current_participatory_process.title
          end
        end

        def answer_participation
          participation.update_attributes!(
            state: state,
            answer: @form.answer,
            answered_at: Time.current,
          )
        end

        def state
          if @form.state
            @form.state
          else
            "waiting_for_validation"
          end
        end

        def update_moderation
          participation.moderation.update_attributes(sqr_status: "authorized") if participation.state == "accepted"
        end
      end
    end
  end
end
