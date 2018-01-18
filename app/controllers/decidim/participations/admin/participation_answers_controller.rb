# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      # This controller allows admins to answer participations in a participatory process.
      class ParticipationAnswersController < Admin::ApplicationController
        helper_method :participation

        def edit
          if current_user.roles.include?("moderator")
            @moderator_view = true
          elsif current_user.roles.include?("cpdp")
            @cpdp_view = true
          elsif current_user.roles.include?("moa")
            @moa_view = true
          end 
          authorize! :update, participation
          @form = form(Admin::ParticipationAnswerForm).from_model(participation)
        end

        def update
          authorize! :update, participation
          @form = form(Admin::ParticipationAnswerForm).from_params(params)

          Admin::AnswerParticipation.call(@form, participation) do
            on(:ok) do
              flash[:notice] = I18n.t("participations.answer.success", scope: "decidim.participations.admin")
              redirect_to participations_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("participations.answer.invalid", scope: "decidim.participations.admin")
              render action: "edit"
            end
          end
        end

        private

        def participation
          @participations ||= Participation.where(feature: current_feature).find(params[:id])
        end
      end
    end
  end
end
