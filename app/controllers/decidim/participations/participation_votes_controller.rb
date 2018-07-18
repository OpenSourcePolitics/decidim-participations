# frozen_string_literal: true

module Decidim
  module Participations
    # Exposes the participation vote resource so users can vote participations.
    class ParticipationVotesController < Decidim::Participations::ApplicationController
      include ParticipationVotesHelper

      helper_method :participation

      before_action :authenticate_user!

      def create
        enforce_permission_to :vote, participation
        @from_participations_list = params[:from_participations_list] == "true"

        VoteParticipation.call(participation, current_user) do
          on(:ok) do
            participation.reload
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: { error: I18n.t("participation_votes.create.error", scope: "decidim.participations") }, status: 422
          end
        end
      end

      def destroy
        enforce_permission_to :unvote, participation
        @from_participations_list = params[:from_participations_list] == "true"

        UnvoteParticipation.call(participation, current_user) do
          on(:ok) do
            participation.reload
            render :update_buttons_and_counters
          end
        end
      end

      private

      def participation
        @participation ||= Participation.where(component: current_component).find(params[:participation_id])
      end
    end
  end
end
