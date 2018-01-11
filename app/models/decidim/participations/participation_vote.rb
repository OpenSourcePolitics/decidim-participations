# frozen_string_literal: true

module Decidim
  module Participations
    # A participation can include a vote per user.
    class ParticipationVote < ApplicationRecord
      belongs_to :participation, foreign_key: "decidim_participation_id", class_name: "Decidim::Participations::Participation", counter_cache: true
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      validates :participation, uniqueness: { scope: :author }
      validate :author_and_participation_same_organization
      validate :participation_not_rejected

      private

      # Private: check if the participation and the author have the same organization
      def author_and_participation_same_organization
        return if !participation || !author
        errors.add(:participation, :invalid) unless author.organization == participation.organization
      end

      def participation_not_rejected
        return unless participation
        errors.add(:participation, :invalid) if participation.rejected?
      end
    end
  end
end
