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
        def initialize(form, participation)
          @form = form
          @participation = participation
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
          update_answer_state
          update_moderation
          broadcast(:ok)
        end

        private

        attr_reader :form, :participation

        def answer_participation
          participation.update_attributes!(
            state: @form.state,
            answer: @form.answer,
            answered_at: Time.current,
            #justification
          )
        end

        def update_answer_state
          if participation.answer_state == "waiting_for_answer" && participation.answer.present?
            participation.update_attributes(answer_state: "waiting_for_validation")
          end
        end

        def update_moderation
          participation.moderation.update_attributes(upstream_moderation: "authorized") if participation.state == "accepted"
        end
      end
    end
  end
end
