# frozen_string_literal: true

module Decidim
  module Participations
    # A command with all the business logic when a user creates a new participation.
    class CreateParticipation < Rectify::Command
      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      def initialize(form, current_user)
        @form = form
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the participation.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if participation_limit_reached?
          form.errors.add(:base, I18n.t("decidim.participations.new.limit_reached"))
          return broadcast(:invalid)
        end

        if process_attachments?
          build_attachment
          return broadcast(:invalid) if attachment_invalid?
        end

        transaction do
          create_participation
          create_attachment if process_attachments?
          send_notification
        end

        send_notification_to_moderators
        broadcast(:ok, participation)
      end

      private

      def send_notification
        return if participation.author.blank?

        Decidim::EventsManager.publish(
          event: "decidim.events.participations.participation_created",
          event_class: Decidim::Participations::ParticipationCreatedEvent,
          resource: participation,
          recipient_ids: participation.author.id
        )
      end

      attr_reader :form, :participation, :attachment

      def create_participation
        @participation = Participation.create!(
          body: form.body,
          participation_type: form.participation_type,
          category: form.category,
          scope: form.scope,
          author: @current_user,
          decidim_user_group_id: form.user_group_id,
          feature: form.feature,
          address: form.address,
          latitude: form.latitude,
          longitude: form.longitude
        )
      end

      def send_notification_to_moderators
        Decidim::EventsManager.publish(
          event: "decidim.events.participations.participation_created",
          event_class: Decidim::Participations::ParticipationCreatedEvent,
          resource: @participation,
          recipient_ids: (@participation.users_to_notify_on_participation_created - [@participation.author]).pluck(:id),
          extra: {
            moderation_event: true,
            new_content: true,
            process_slug: @participation.feature.participatory_space.slug
          }
        )
      end

      def build_attachment
        @attachment = Attachment.new(
          title: form.attachment.title,
          file: form.attachment.file,
          attached_to: @participation
        )
      end

      def attachment_invalid?
        if attachment.invalid? && attachment.errors.has_key?(:file)
          form.attachment.errors.add :file, attachment.errors[:file]
          true
        end
      end

      def attachment_present?
        form.attachment.file.present?
      end

      def create_attachment
        attachment.attached_to = participation
        attachment.save!
      end

      def attachments_allowed?
        true
      end

      def process_attachments?
        attachments_allowed? && attachment_present?
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
        @organization ||= @current_user.organization
      end

      def current_user_participations
        Participation.where(author: @current_user, feature: form.current_feature)
      end

      def user_group_participations
        Participation.where(user_group: @user_group, feature: form.current_feature)
      end
    end
  end
end
