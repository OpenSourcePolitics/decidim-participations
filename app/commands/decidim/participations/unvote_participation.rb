# frozen_string_literal: true

module Decidim
  module Participations
    # A command with all the business logic when a user unvotes a participation.
    class UnvoteParticipation < Rectify::Command
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
      # - :ok when everything is valid, together with the participation.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        destroy_participation_vote
        broadcast(:ok, @participation)
      end

      private

      def destroy_participation_vote
        @participation.votes.where(author: @current_user).destroy_all
      end
    end
  end
end
