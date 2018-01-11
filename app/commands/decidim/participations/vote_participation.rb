# frozen_string_literal: true

module Decidim
  module Participations
    # A command with all the business logic when a user votes a participation.
    class VoteParticipation < Rectify::Command
      # Public: Initializes the command.
      #
      # participation     - A Decidim::Participations::Participation object.
      # current_user - The current user.
      def initialize(participation, current_user)
        @participation = participation
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the participation vote.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if @participation.maximum_votes_reached?

        build_participation_vote
        return broadcast(:invalid) unless vote.valid?

        vote.save!
        broadcast(:ok, vote)
      end

      attr_reader :vote

      private

      def build_participation_vote
        @vote = @participation.votes.build(author: @current_user)
      end
    end
  end
end
