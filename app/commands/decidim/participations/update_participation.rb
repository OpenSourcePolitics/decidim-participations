# frozen_string_literal: true

module Decidim
  module Participations
    # A command with all the business logic when a user updates a participation.
    class UpdateParticipation < Rectify::Command
      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # participation - the participation to update.
      def initialize(form, current_user, participation)
        @form = form
        @current_user = current_user
        @participation = participation
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the participation.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?
        return broadcast(:invalid) unless participation.editable_by?(current_user)
        return broadcast(:invalid) if participation_limit_reached?

        transaction do
          update_participation
        end

        broadcast(:ok, participation)
      end

      private

      attr_reader :form, :participation, :current_user

      def update_participation
        @participation.update_attributes!(
          body: form.body,
          participation_type: form.participation_type,
          category: form.category,
          scope: form.scope,
          author: current_user,
          decidim_user_group_id: user_group.try(:id),
          address: form.address,
          latitude: form.latitude,
          longitude: form.longitude
        )
      end

      def participation_limit_reached?
        participation_limit = form.current_component.settings.participation_limit

        return false if participation_limit.zero?

        if user_group
          user_group_participations.count >= participation_limit
        else
          current_user_participations.count >= participation_limit
        end
      end

      def user_group
        @user_group ||= Decidim::UserGroup.where(organization: organization, id: form.user_group_id).first
      end

      def organization
        @organization ||= current_user.organization
      end

      def current_user_participations
        Participation.where(author: current_user, component: form.current_component).where.not(id: participation.id)
      end

      def user_group_participations
        Participation.where(user_group: user_group, component: form.current_component).where.not(id: participation.id)
      end
    end
  end
end
