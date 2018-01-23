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
          authorize! :read, Participation
          case params[:status]
            when "unmoderate"
              @param_unmoderate = true
            when "questions"
              @param_questions = true
            when "moderated"
              @param_moderated = true
            else
              default_param
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
          authorize! :update, Participation
          @form = form(Admin::ParticipationForm).from_model(participation)
        end

        def update
          authorize! :update, Participation
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

        def default_param
          if can? :manage, Decidim::Participations::Participation
            @param_unmoderate = true
          else
            @param_questions = true
          end
        end

        def query
          @query ||=
            if @param_unmoderate
              Participation.untreated(current_feature).ransack(params[:q])
            elsif @param_questions
              filtered_questions
            elsif @param_moderated
              filtered_treated
            end
        end

        def filtered_questions
          if can? :manage, Decidim::Participations::Participation
            Participation.filtered_questions(current_feature).ransack(params[:q])
          else
            Participation.filtered_questions_per_role(current_feature, current_user_role, "waiting_for_answer").ransack(params[:q])
          end
        end

        def filtered_treated
          if can? :manage, Decidim::Participations::Participation
            Participation.treated(current_feature).ransack(params[:q])
          else
            Participation.filtered_questions_per_role(current_feature, current_user_role, "authorized").ransack(params[:q])
          end
        end

        def current_user_role
          ParticipatoryProcessUserRole.where(user: current_user).first.role
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
