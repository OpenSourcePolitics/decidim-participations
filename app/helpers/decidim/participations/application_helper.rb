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
    end
  end
end
