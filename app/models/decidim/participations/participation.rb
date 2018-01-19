# frozen_string_literal: true

module Decidim
  module Participations
    # The data store for a Participation in the Decidim::Participations component.
    class Participation < Participations::ApplicationRecord
      include Decidim::Resourceable
      include Decidim::Authorable
      include Decidim::HasFeature
      include Decidim::HasScope
      include Decidim::HasReference
      include Decidim::HasCategory
      include Decidim::Reportable
      include Decidim::HasAttachments
      include Decidim::Followable
      include Decidim::Comments::Commentable

      feature_manifest_name "participations"

      accepts_nested_attributes_for :moderation

      has_many :votes, foreign_key: "decidim_participation_id", class_name: "ParticipationVote", dependent: :destroy, counter_cache: "participation_votes_count"

      validates :body, presence: true

      geocoded_by :address, http_headers: ->(participation) { { "Referer" => participation.feature.organization.host } }

      # upstream moderation => MOA dashboard
      scope :untreated, ->(current_feature) { current_feature_participations(current_feature).joins(:moderation).merge(Moderation.where(upstream_moderation: "unmoderate")) }
      scope :treated, -> (current_feature){ current_feature_participations(current_feature).joins(:moderation).merge(Moderation.where('upstream_moderation = ? OR upstream_moderation = ?', 'authorized', 'refused')) }
      scope :questions_with_unpublished_answer, -> (current_feature) { current_feature_participations(current_feature).joins(:moderation).merge(Moderation.where.not(['upstream_moderation = ? OR upstream_moderation = ? OR upstream_moderation = ?', 'unmoderate', 'authorized', 'refused'])) }

      # participations index
      scope :exclude, lambda { |status |left_outer_joins(:moderation).where(Decidim::Moderation.arel_table[:upstream_moderation].not_eq(status))}

      scope :accepted, -> { where(state: "accepted") }
      scope :rejected, -> { where(state: "rejected") }
      scope :evaluating, -> { where(state: "evaluating") }
      after_create :create_participation_moderation

      def self.current_feature_participations(current_feature)
        where(feature: current_feature)
      end

      def question?
        type == "question"
      end

      def published?
        published_on.present?
      end

      def not_publish?
        published_on.nil?
      end

      def publishable?
        moderation.upstream_moderation == "authorized" || moderation.upstream_moderation == "waiting_for_answer"
      end

      def type
        participation_type
      end

      def refused?
        moderation.upstream_moderation == "refused"
      end

      def generate_title # count the number of authorized and waiting for answer status. Then generate the title thanks to this number
        status = self.class.where(participation_type: type).map(&:moderation).map(&:upstream_moderation)
        status.delete("refused")
        status.delete("unmoderate")
        number = status.count
        "#{type.capitalize}" + " n°" + "#{number}"
      end


      def self.find_participations(participations)
        where(id: participations.map(&:id))
      end

      def self.order_randomly(seed)
        transaction do
          connection.execute("SELECT setseed(#{connection.quote(seed)})")
          order("RANDOM()").load
        end
      end

      # Public: Check if the user has voted the participation.
      #
      # Returns Boolean.
      def voted_by?(user)
        votes.where(author: user).any?
      end

      # Public: Checks if the organization has given an answer for the participation.
      #
      # Returns Boolean.
      def answered?
        answered_at.present?
      end

      # Public: Checks if the organization has accepted a participation.
      #
      # Returns Boolean.
      def accepted?
        answered? && state == "accepted"
      end

      # Public: Checks if the organization has rejected a participation.
      #
      # Returns Boolean.
      def rejected?
        answered? && state == "rejected"
      end

      # Public: Checks if the organization has marked the participation as evaluating it.
      #
      # Returns Boolean.
      def evaluating?
        answered? && state == "evaluating"
      end

      # Public: Overrides the `commentable?` Commentable concern method.
      def commentable?
        feature.settings.comments_enabled?
      end

      # Public: Overrides the `accepts_new_comments?` Commentable concern method.
      def accepts_new_comments?
        commentable? && !feature.current_settings.comments_blocked
      end

      # Public: Overrides the `comments_have_alignment?` Commentable concern method.
      def comments_have_alignment?
        true
      end

      # Public: Overrides the `comments_have_votes?` Commentable concern method.
      def comments_have_votes?
        true
      end

      # Public: Overrides the `reported_content_url` Reportable concern method.
      def reported_content_url
        ResourceLocatorPresenter.new(self).url
      end

      def users_to_notify_on_participation_created
        get_all_users_with_role
      end


      # Public: Override Commentable concern method `users_to_notify_on_comment_authorized`
      def users_to_notify_on_comment_authorized
        return (followers | feature.participatory_space.admins).uniq if official?
        followers
      end

      # Public: Whether the participation is official or not.
      def official?
        author.nil?
      end

      # Public: The maximum amount of votes allowed for this participation.
      #
      # Returns an Integer with the maximum amount of votes, nil otherwise.
      def maximum_votes
        maximum_votes = feature.settings.maximum_votes_per_participation
        return nil if maximum_votes.zero?

        maximum_votes
      end

      # Public: The maximum amount of votes allowed for this participation. 0 means infinite.
      #
      # Returns true if reached, false otherwise.
      def maximum_votes_reached?
        return false unless maximum_votes

        votes.count >= maximum_votes
      end

      # Checks whether the user is author of the given participation, either directly
      # authoring it or via a user group.
      #
      # user - the user to check for authorship
      def authored_by?(user)
        author == user || user.user_groups.include?(user_group)
      end

      # Checks whether the user can edit the given participation.
      #
      # user - the user to check for authorship
      def editable_by?(user)
        authored_by?(user) && !answered? && within_edit_time_limit?
      end

      # method for sort_link by number of comments
      ransacker :commentable_comments_count do
        query = <<-SQL
              (SELECT COUNT(decidim_comments_comments.id)
                 FROM decidim_comments_comments
                WHERE decidim_comments_comments.decidim_commentable_id = decidim_participations_participations.id
                  AND decidim_comments_comments.decidim_commentable_type = 'Decidim::Participations::Participation'
                GROUP BY decidim_comments_comments.decidim_commentable_id
              )
            SQL
        Arel.sql(query)
      end

      private

      # Checks whether the participation is inside the time window to be editable or not.
      def within_edit_time_limit?
        limit = created_at + feature.settings.participation_edit_before_minutes.minutes
        Time.current < limit
      end

      def create_participation_moderation
        participatory_space = self.feature.participatory_space
        self.create_moderation!(participatory_space: participatory_space)
      end

      def upstream_moderation_activated?
        feature.settings.upstream_moderation_enabled
      end
    end
  end
end
