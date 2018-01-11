# frozen_string_literal: true

module Decidim
  module Participations
    module Abilities
      # Defines the abilities related to participations for a logged in user.
      # Intended to be used with `cancancan`.
      class CurrentUserAbility
        include CanCan::Ability

        attr_reader :user, :context

        def initialize(user, context)
          return unless user

          @user = user
          @context = context

          can :vote, Participation do |_participation|
            authorized?(:vote) && voting_enabled? && remaining_votes.positive?
          end

          can :unvote, Participation do |_participation|
            authorized?(:vote) && voting_enabled?
          end

          can :create, Participation if authorized?(:create) && creation_enabled?
          can :edit, Participation do |participation|
            participation.editable_by?(user)
          end

          can :report, Participation
        end

        private

        def authorized?(action)
          return unless feature

          ActionAuthorizer.new(user, feature, action).authorize.ok?
        end

        def vote_limit_enabled?
          return unless feature_settings
          feature_settings.vote_limit.present? && feature_settings.vote_limit.positive?
        end

        def creation_enabled?
          return unless current_settings
          current_settings.creation_enabled?
        end

        def remaining_votes
          return 1 unless vote_limit_enabled?

          participations = Participation.where(feature: feature)
          votes_count = ParticipationVote.where(author: user, participation: participations).size
          feature_settings.vote_limit - votes_count
        end

        def voting_enabled?
          return unless current_settings
          current_settings.votes_enabled? && !current_settings.votes_blocked?
        end

        def current_settings
          context.fetch(:current_settings, nil)
        end

        def feature_settings
          context.fetch(:feature_settings, nil)
        end

        def feature
          feature = context.fetch(:current_feature, nil)
          return nil unless feature && feature.manifest.name == :participations

          feature
        end
      end
    end
  end
end
