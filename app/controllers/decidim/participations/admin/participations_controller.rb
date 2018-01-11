# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      # This controller allows admins to manage participations in a participatory process.
      class ParticipationsController < Admin::ApplicationController
        helper Participations::ApplicationHelper
        helper_method :participations, :query

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

        private

        def query
          @query ||= Participation.where(feature: current_feature).ransack(params[:q])
        end

        def participations
          @participations ||= query.result.page(params[:page]).per(15)
        end

        def participation
          @participation ||= Participation.where(feature: current_feature).find(params[:id])
        end
      end
    end
  end
end
