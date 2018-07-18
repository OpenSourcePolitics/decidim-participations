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
          enforce_permission_to :read, :participation
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
          enforce_permission_to :create, :participation
          @form = form(Admin::ParticipationForm).from_params(
            attachment: form(AttachmentForm).from_params({})
          )
        end

        def create
          enforce_permission_to :create, :participation
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
          enforce_permission_to :update, :participation, participation: @participation
          @form = form(Admin::ParticipationForm).from_model(participation)
        end

        def update
          enforce_permission_to :update, :participation, participation: @participation
          @form = form(Admin::ParticipationForm).from_params(params)

          Admin::UpdateParticipation.call(@form, current_user, current_participatory_space, participation) do
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
          if allowed_to? :manage, Decidim::Participations::Participation
            @param_unmoderate = true
          else
            @param_questions = true
          end
        end

        def query
          @query ||=
            if @param_unmoderate
              Participation.untreated(current_component).ransack(params[:q])
            elsif @param_questions
              filtered_questions
            elsif @param_moderated
              filtered_treated
            end
        end

        def filtered_questions
          if allowed_to? :manage, Decidim::Participations::Participation
            Participation.filtered_questions(current_component).ransack(params[:q])
          else
            Participation.filtered_questions_per_role(current_component, current_user_role, "waiting_for_answer").ransack(params[:q])
          end
        end

        def filtered_treated
          if allowed_to? :manage, Decidim::Participations::Participation
            Participation.treated(current_component).ransack(params[:q])
          else
            Participation.filtered_questions_per_role(current_component, current_user_role, "authorized").ransack(params[:q])
          end
        end

        def current_user_role
          ParticipatoryProcessUserRole.where(user: current_user).first.role
        end

        def participations
          @participations ||= query.result.page(params[:page]).per(15)
        end

        def participation
          @participation ||= Participation.current_component_participations(current_component).find(params[:id])
        end
      end
    end
  end
end
