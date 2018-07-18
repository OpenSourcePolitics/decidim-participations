# frozen_string_literal: true

module Decidim
  module Participations
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless user

        # Delegate the admin permission checks to the admin permissions class
        return Decidim::Participations::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin
        return permission_action if permission_action.scope != :public

        return permission_action if permission_action.subject != :participation

        case permission_action.action
        when :create
          can_create_participation?
        when :edit
          can_edit_participation?
        when :vote
          can_vote_participation?
        when :unvote
          can_unvote_participation?
        when :report
          true
        end

        permission_action
      end

      private

      def participation
        @participation ||= context.fetch(:participation, nil)
      end

      def voting_enabled?
        return unless current_settings
        current_settings.votes_enabled? && !current_settings.votes_blocked?
      end

      def vote_limit_enabled?
        return unless component_settings
        component_settings.vote_limit.present? && component_settings.vote_limit.positive?
      end

      def remaining_votes
        return 1 unless vote_limit_enabled?

        participations = Proposal.where(component: component)
        votes_count = ProposalVote.where(author: user, participation: participations).size
        component_settings.vote_limit - votes_count
      end

      def can_create_participation?
        toggle_allow(authorized?(:create) && current_settings&.creation_enabled?)
      end

      def can_edit_participation?
        toggle_allow(participation && participation.editable_by?(user))
      end

      def can_vote_participation?
        is_allowed = participation &&
                     authorized?(:vote) &&
                     voting_enabled? &&
                     remaining_votes.positive?

        toggle_allow(is_allowed)
      end

      def can_unvote_participation?
        is_allowed = participation &&
                     authorized?(:vote) &&
                     voting_enabled?

        toggle_allow(is_allowed)
      end
    end
  end
end
