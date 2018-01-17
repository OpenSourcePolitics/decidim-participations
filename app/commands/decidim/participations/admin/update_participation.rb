module Decidim
  module Participations
    module Admin
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
            binding.pry
            update_participation
            update_moderation
          end

          broadcast(:ok, participation)
        end

        private

        attr_reader :form, :participation, :current_user

        def update_participation
          binding.pry
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

        def update_moderation
          @moderation = @participation.moderation.update_attributes(
            upstream_moderation: form.moderation.upstream_moderation,
            justification: form.moderation.justification,
          )
        end


        def participation_limit_reached?
          participation_limit = form.current_feature.settings.participation_limit

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
          Participation.where(author: current_user, feature: form.current_feature).where.not(id: participation.id)
        end

        def user_group_participations
          Participation.where(user_group: user_group, feature: form.current_feature).where.not(id: participation.id)
        end
      end
    end
  end
end