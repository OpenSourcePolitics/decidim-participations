# frozen_string_literal: true

module Decidim
  module Participations
    # Exposes the participation resource so users can view and create them.
    class ParticipationsController < Decidim::Participations::ApplicationController
      helper Decidim::WidgetUrlsHelper
      include FormFactory
      include FilterResource
      include Orderable
      include Paginable

      helper_method :geocoded_participations
      before_action :authenticate_user!, only: [:new, :create]

      def index
        @participations = search
                      .results
                      .not_hidden
                      .exclude("unmoderate")
                      .exclude("refused")
                      .includes(:author)
                      .includes(:category)
                      .includes(:scope)

        @voted_participations = if current_user
                             ParticipationVote.where(
                               author: current_user,
                               participation: @participations.pluck(:id)
                             ).pluck(:decidim_participation_id)
                           else
                             []
                           end

        @participations = paginate(@participations)
        @participations = reorder(@participations)
      end

      def show
        @participation = Participation
                    .not_hidden
                    .where(component: current_component)
                    .find(params[:id])
        @report_form = form(Decidim::ReportForm).from_params(reason: "spam")
      end

      def new
        enforce_permission_to :create, :participation

        @form = form(ParticipationForm).from_params(
          attachment: form(AttachmentForm).from_params({})
        )
      end

      def create
        enforce_permission_to :create, :participation

        @form = form(ParticipationForm).from_params(params)

        CreateParticipation.call(@form, current_user) do
          on(:ok) do |participation|
            flash[:notice] = I18n.t("participations.create.success", scope: "decidim")
            redirect_to participation_path(participation)
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("participations.create.error", scope: "decidim")
            render :new
          end
        end
      end

      def edit
        @participation = Participation.not_hidden.where(component: current_component).find(params[:id])
        enforce_permission_to :edit, :participation, participation: @participation

        @form = form(ParticipationForm).from_model(@participation)
      end

      def update
        @participation = Participation.not_hidden.where(component: current_component).find(params[:id])
        enforce_permission_to :edit, :participation, participation: @participation

        @form = form(ParticipationForm).from_params(params)
        UpdateParticipation.call(@form, current_user, @participation) do
          on(:ok) do |participation|
            flash[:notice] = I18n.t("participations.update.success", scope: "decidim")
            redirect_to participation_path(participation)
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("participations.update.error", scope: "decidim")
            render :edit
          end
        end
      end

      private

      def get_user_with_process_role(participatory_process_id)
        Decidim::ParticipatoryProcessUserRole.where(decidim_participatory_process_id: participatory_process_id).map(&:user)
      end


      def admin_or_moderator?
        current_user && (current_user.admin? ||
          current_organization.users_with_any_role.include?(current_user) ||
          get_user_with_process_role(current_participatory_process.id).include?(current_user)
        )
      end

      def geocoded_participations
        @geocoded_participations ||= search.results.not_hidden.select(&:geocoded?)
      end

      def search_klass
        ParticipationSearch
      end

      def default_filter_params
        {
          participation_type: "all",
          search_text: "",
          origin: "",
          activity: "",
          category_id: "",
          state: "all",
          scope_id: nil,
          related_to: ""
        }
      end
    end
  end
end
