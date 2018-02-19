# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      # This controller allows admins to answer participations in a participatory process.
      class ParticipationAnswersController < Admin::ApplicationController
        helper_method :participation

        def edit
          # Avoid useless options when cpdp answers to its own questions
          process_role = ParticipatoryProcessUserRole.where(user: current_user).first
          if process_role.present? && process_role.role == "cpdp"
            @cpdp_to_cpdp = participation.recipient_role == process_role.role
          else
            @cpdp_to_cpdp = ""
          end
          
          authorize! :update, participation
          @form = form(Admin::ParticipationAnswerForm).from_model(participation)
        end

        def update
          authorize! :update, participation
          @form = form(Admin::ParticipationAnswerForm).from_params(params)

          Admin::AnswerParticipation.call(@form, participation, current_participatory_space) do
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
