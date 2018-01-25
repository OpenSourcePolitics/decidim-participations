module Decidim
  module Participations
    module Admin
      class UpdateParticipation < Rectify::Command
        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # current_user - The current user.
        # current_participatory_process - The current participatory process
        # participation - the participation to update.
        def initialize(form, current_user, current_participatory_process, participation)
          @form = form
          @current_user = current_user
          @current_participatory_process = current_participatory_process
          @participation = participation
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the participation.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          transaction do
            should_notify = recipient_role_will_change?
            update_participation
            update_moderation
            update_title
            update_publishing
            set_deadline
            send_notification_new_question if should_notify
          end

          broadcast(:ok, participation)
        end

        private

        attr_reader :form, :participation, :current_user

        def update_participation
          @participation.update_attributes!(
            body: form.body,
            participation_type: form.participation_type,
            category: form.category,
            recipient_role: form.recipient_role
          )
        end

        def update_moderation
          @moderation = @participation.moderation.update_attributes(
            upstream_moderation: set_upstream_moderation,
            justification: form.moderation.justification,
            id: @participation.moderation.id
          )
        end

        def set_upstream_moderation
          if @participation.question? && form.moderation.upstream_moderation == "authorized"
            "waiting_for_answer"
          else
            form.moderation.upstream_moderation
          end
        end

        def participation_limit_reached?
          participation_limit = form.current_feature.settings.participation_limit

          return false if participation_limit.zero?

          if user_group
            user_group_participations.count >= participation_limit
          else
            current_user_participations.count >= participation_limit
          end
        end

        def recipient_role_will_change?
          form.recipient_role != participation.recipient_role && (form.participation_type == "question")
        end

        def send_notification_new_question
          recipient_ids = Decidim::ParticipatoryProcessUserRole.where(decidim_participatory_process_id: @current_participatory_process.id, role: participation.recipient_role).map(&:decidim_user_id)
          title = @current_participatory_process.title.is_a?(Hash) ? @current_participatory_process.title[I18n.locale.to_s] : @current_participatory_process.title

          Decidim::EventsManager.publish(
            event: "decidim.events.participations.new_question",
            event_class: Decidim::Participations::NewParticipationQuestionEvent,
            resource: @participation,
            recipient_ids: recipient_ids.uniq,
            extra: {
              question_attributed: true,
              participatory_process_title: title
            }
          )
        end

        def organization
          @organization ||= current_user.organization
        end

        def current_user_participations
          Participation.where(author: current_user, feature: form.current_feature).where.not(id: participation.id)
        end

        def user_group_participations
          Participation.where(user_group: user_group, feature: form.current_feature).where.not(id: participation.id)
        end

        def update_publishing
          if @participation.not_publish? && @participation.publishable?
            @participation.update_attributes(published_on: Time.zone.now)
            update_state
          elsif !@participation.publishable?
            @participation.update_attributes(published_on: nil)
          end
        end

        def update_title
          if !@participation.publishable? || @participation.refused?
            @participation.update_attributes(title: nil)
          else # case : participation is published || A user changed the type of a published participation
            @participation.update_attributes(title: @participation.generate_title)
          end
        end

        def update_state
          if @participation.question? && @participation.answer.nil?
            @participation.update_attributes(state: "waiting_for_answer")
          end
        end

        def set_deadline
          @participation.update_attributes(answer_deadline: @participation.published_on + 15.days) if @participation.question? && participation.published?
        end
      end
    end
  end
end