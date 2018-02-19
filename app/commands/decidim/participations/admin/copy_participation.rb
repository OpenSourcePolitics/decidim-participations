# frozen_string_literal: true

module Decidim
    module Participations
      module Admin
        # A command with all the business logic when copying a new participation
        # in the system.
        class CopyParticipation < Rectify::Command
          # Public: Initializes the command.
          #
          # participation - A participation we want to duplicate
          def initialize(participation)
            @participation = participation
          end

          # Executes the command. Broadcasts these events:
          #
          # - :ok when everything is valid.
          # - :invalid if the form wasn't valid and we couldn't proceed.
          #
          # Returns nothing.
          def call
            return broadcast(:invalid) if @participation.invalid?

            Participation.transaction do
              copy_participation
            end

            broadcast(:ok, @copied_process)
          end

          private

          def copy_participation
            @copied_process = Participation.create!(
                body: [I18n.t("participations.copy.prefix", scope: "decidim.participations.admin"), @participation.original_body.to_s].join(" "),
                original_body: @participation.body,
                participation_type: @participation.participation_type,
                category: @participation.category,
                scope: @participation.scope,
                author: @participation.author,
                decidim_user_group_id: @participation.decidim_user_group_id,
                feature: @participation.feature,
                address: @participation.address,
                latitude: @participation.latitude,
                longitude: @participation.longitude
            )
          end

        end
      end
    end
end
