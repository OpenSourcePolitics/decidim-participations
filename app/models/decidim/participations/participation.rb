# frozen_string_literal: true

module Decidim
  module Participations
    # The data store for a Participation in the Decidim::Participations component.
    class Participation < Participations::ApplicationRecord
      include Decidim::Resourceable
      include Decidim::Authorable
      include Decidim::HasComponent
      include Decidim::ScopableComponent
      include Decidim::HasReference
      include Decidim::HasCategory
      include Decidim::Reportable
      # include Decidim::Participations::CommentableParticipation
      include Decidim::Searchable
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::Fingerprintable
      # Provides a way to track changes in your object
      include ActiveModel::Dirty

      component_manifest_name "participations"

      accepts_nested_attributes_for :moderation

      has_many :votes, foreign_key: "decidim_participation_id", class_name: "ParticipationVote", dependent: :destroy, counter_cache: "participation_votes_count"

      validates :body, presence: true

      geocoded_by :address, http_headers: ->(participation) { { "Referer" => participation.component.organization.host } }

      # upstream moderation => MOA dashboard
      scope :untreated, ->(current_component) {
        current_component_participations(current_component)
        .joins(:moderation)
        .merge(Moderation.where(sqr_status: "unmoderate")) }


      scope :filtered_questions, -> (current_component) { current_component_participations(current_component)
        .joins(:moderation)
        .merge(Moderation.where.not(['sqr_status = ? OR sqr_status = ? OR sqr_status = ?', 'unmoderate', 'authorized', 'refused'])) }

      scope :filtered_questions_per_role,  lambda { |current_component, role, sqr_status|
        current_component_participations(current_component)
          .where(participation_type: "question", recipient_role: role)
          .joins(:moderation)
          .merge(Moderation.where(['sqr_status = ?', sqr_status]))
      }

      scope :treated, -> (current_component){
        current_component_participations(current_component)
        .joins(:moderation)
        .merge(Moderation.where('sqr_status = ? OR sqr_status = ?', 'authorized', 'refused')) }

      # participations index

      scope :exclude, lambda { |status |left_outer_joins(:moderation).where(Decidim::Moderation.arel_table[:sqr_status].not_eq(status))}

      scope :accepted, -> { where(state: "accepted") }
      scope :rejected, -> { where(state: "rejected") }
      scope :evaluating, -> { where(state: "evaluating") }
      after_create :create_participation_moderation

      # filter index
      scope :filter_per_moderation_status,  lambda { |state|
        joins(:moderation).merge(Moderation.where(['sqr_status = ?', state]))
      }

      # filter dashboard

      ransacker :status do
        query = <<-SQL
              (SELECT decidim_moderations.sqr_status
                 FROM decidim_moderations
                WHERE decidim_moderations.decidim_reportable_id = decidim_participations_participations.id
                  AND decidim_moderations.decidim_reportable_type = 'Decidim::Participations::Participation'
                GROUP BY decidim_moderations.sqr_status
              )
            SQL
        Arel.sql(query)
      end

      def self.current_component_participations(current_component)
        where(component: current_component)
      end

      def question?
        type == "question"
      end

      def opinion?
        type == "opinion"
      end

      def contribution?
        type == "contribution"
      end

      def published?
        published_on.present?
      end

      def not_publish?
        published_on.nil?
      end

      def publishable?
        moderation.sqr_status == "authorized" || moderation.sqr_status == "waiting_for_answer"
      end

      def authorized?
        moderation.sqr_status == "authorized"
      end

      def unmoderate?
        moderation.sqr_status == "unmoderate"
      end

      def type
        participation_type
      end

      def refused?
        moderation.sqr_status == "refused"
      end

      def generate_title(current_component) # count the number of "authorized" and "waiting for answer" status. Then generate the title thanks to this number
        status = self.class.where(participation_type: participation_type, component: current_component).map(&:moderation).map(&:sqr_status)
        status.delete("refused")
        status.delete("unmoderate")

        status_count = status.count
        type = I18n.t("decidim.participations.admin.participations.title.#{self.type}")
        title = "#{type}" + " n°" + "#{status_count}"
        titles = self.class.where(participation_type: participation_type, component: current_component).map(&:title)
        while titles.include?(title)
          title = "#{type}" + " n°" + "#{status_count}"
          status_count += 1
        end
        title
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

      # Public: Check if the participation is waiting for MOA moderation
      #
      # Returns Boolean.
      def waiting_for_validation?
        state == "waiting_for_validation"
      end

      # Public: Check if the participation is incomplete
      #
      # Returns Boolean.
      def incomplete?
        state == "incomplete"
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
        if published_answer?
          return component.settings.comments_enabled?
        elsif opinion? || contribution?
          return component.settings.comments_enabled?
        end
        return false
      end

      def published_answer?
        question? && answered? && published? && state == "accepted"
      end
      # Public: Overrides the `accepts_new_comments?` Commentable concern method.
      def accepts_new_comments?
        commentable? && !component.current_settings.comments_blocked
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
        get_users_with_main_roles
      end

      def users_to_notify_on_comment_created
        get_users_with_main_roles
      end

      def get_users_with_main_roles # Exclude MOA
        component.participatory_space.admins +
        Decidim::ParticipatoryProcessUserRole.where(decidim_participatory_process_id: component.participatory_space.id).where.not(role: "moa").map(&:user)
      end


      # Public: Override Commentable concern method `users_to_notify_on_comment_authorized`
      def users_to_notify_on_comment_authorized
        return (followers | component.participatory_space.admins).uniq if official?
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
        maximum_votes = component.settings.maximum_votes_per_participation
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
        limit = created_at + component.settings.participation_edit_before_minutes.minutes
        Time.current < limit
      end

      def create_participation_moderation
        participatory_space = self.component.participatory_space
        self.create_moderation!(participatory_space: participatory_space, upstream_moderation: nil)
      end
    end
  end
end
