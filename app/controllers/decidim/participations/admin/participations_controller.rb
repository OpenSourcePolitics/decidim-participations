# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      # This controller allows admins to manage participations in a participatory process.
      class ParticipationsController < Admin::ApplicationController
        helper Participations::ApplicationHelper
        helper Decidim::Messaging::ConversationHelper

        helper_method :participations, :query

        def index
          if can? :update, Decidim::Participations::Participation
            case params[:status]
              when "unmoderate"
                @param_unmoderate = true
              when "questions"
                @param_questions = true
              when "moderated"
                @param_moderated = true
              else
                @param_unmoderate = true
            end
          else
            @param_questions = true
          end
        end

        def new
          authorize! :create, Participation
          @form = form(Admin::ParticipationForm).from_params(
            attachment: form(AttachmentForm).from_params({})
          )
        end

        def create
          authorize! :create, Participation
          @form = form(Admin::ParticipationForm).from_params(params)

          Admin::CreateParticipation.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("participations.create.success", scope: "decidim.participations.admin")
              redirect_to participations_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("participations.create.invalid", scope: "decidim.participations.admin")
              render action: "new"
            end
          end
        end

        def edit
          authorize! :edit, Participation
          @form = form(Admin::ParticipationForm).from_model(participation)
        end

        def update
          authorize! :edit, Participation
          @form = form(Admin::ParticipationForm).from_params(params)

          Admin::UpdateParticipation.call(@form, current_user, participation) do
            on(:ok) do
              flash[:notice] = I18n.t("participations.update.success", scope: "decidim.participations.admin")
              redirect_to participations_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("participations.update.invalid", scope: "decidim.participations.admin")
              render action: "edit"
            end
          end
        end

        private

        def query
          @query ||=
            if @param_unmoderate
              Participation.unmoderate(current_feature).ransack(params[:q])
            elsif @param_questions
               Participation.questions_with_unpublished_answer(current_feature).ransack(params[:q])
            elsif @param_moderated
              Participation.moderated(current_feature).ransack(params[:q])
            end
        end

        def participations
          @participations ||= query.result.page(params[:page]).per(15)
        end

        def participation
          @participation ||= Participation.current_feature_participations(current_feature).find(params[:id])
        end
      end
    end
  end
end
