# frozen_string_literal: true

module Decidim
  module Participations
    class ParticipationWidgetsController < Decidim::WidgetsController
      helper Participations::ApplicationHelper

      private

      def model
        @model ||= Participation.where(feature: params[:feature_id]).find(params[:participation_id])
      end

      def iframe_url
        @iframe_url ||= participation_participation_widget_url(model)
      end
    end
  end
end
