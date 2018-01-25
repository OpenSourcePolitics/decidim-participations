# frozen_string_literal: true

module Decidim
  module Participations
    # Custom helpers, scoped to the participations engine.
    #
    module ApplicationHelper
      include Decidim::Comments::CommentsHelper
      include PaginateHelper
      include ParticipationVotesHelper
      include Decidim::MapHelper
      include Decidim::Participations::MapHelper

      def answer_deadline(participation)
        delay = participation.answer_deadline.mjd - DateTime.now.mjd
        if delay <= 15 && delay >= 10
          content_tag(:strong, class: "text-success") do
            "#{delay}j"
          end
        elsif  delay <= 9 && delay >= 5
          content_tag(:strong, class: "text-info") do
            "#{delay}j"
          end
        elsif  delay <= 4 && delay >= 1
          content_tag(:strong, class: "text-warning") do
            "#{delay}j"
          end
        else
          content_tag(:strong, class: "text-alert") do
            "#{delay}j"
          end
        end
      end

      # Public: The state of a participation in a way a human can understand.
      #
      # state - The String state of the participation.
      #
      # Returns a String.
      def humanize_participation_state(state)
        I18n.t(state, scope: "decidim.participations.answers", default: :not_answered)
      end

      # Public: The css class applied based on the participation state.
      #
      # state - The String state of the participation.
      #
      # Returns a String.
      def participation_state_css_class(state)
        case state
        when "accepted"
          "text-success"
        when "rejected"
          "text-alert"
        when "evaluating"
          "text-info"
        else
          "text-warning"
        end
      end

      def published_status(participation)
        if participation.published? && participation.question?
          "Réponse publiée"
        elsif participation.published?
          "Publiée"
        elsif participation.refused?
          "Refusée"
        end
      end

      def state(participation)
        state = participation.state
        case state
        when "waiting_for_answer"
          content_tag(:strong, class: "text-warning") do
            t(".#{state}")
          end
        when "waiting_for_validation"
          content_tag(:strong, class: "text-info") do
            t(".#{state}")
          end
        when "incomplete"
          content_tag(:strong, class: "text-alert") do
            t(".#{state}")
          end
        end
      end

      def published_status(participation)
        if participation.answered?
          content_tag(:strong, class: 'text-success') do
            t("answer_published" , scope: "decidim.participations.admin.participations.index")
          end
        elsif participation.published?
          content_tag(:strong, class: 'text-success') do
            t("published" , scope: "decidim.participations.admin.participations.index")
          end
        else
          content_tag(:strong, class: 'text-alert') do
            t("refused" , scope: "decidim.participations.admin.participations.index")
          end
        end
      end

      # Public: The css class applied based on the participation state to
      #         the participation badge.
      #
      # state - The String state of the participation.
      #
      # Returns a String.
      def participation_state_badge_css_class(state)
        case state
        when "accepted"
          "success"
        when "rejected"
          "warning"
        when "evaluating"
          "secondary"
        end
      end

      def participation_limit_enabled?
        participation_limit.present?
      end

      def participation_limit
        return if feature_settings.participation_limit.zero?

        feature_settings.participation_limit
      end

      def current_user_participations
        Participation.where(feature: current_feature, author: current_user)
      end

      def participation_roles

        [
          ["moa", t('decidim.admin.models.participatory_process_user_role.roles.moa')],
          ["cpdp", t('decidim.admin.models.participatory_process_user_role.roles.cpdp')]
        ]
      end
    end
  end
end
