# frozen_string_literal: true

module Decidim
  module Participations
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    #
    # Note that it inherits from `Decidim::Components::BaseController`, which
    # override its layout and provide all kinds of useful methods.
    class ApplicationController < Decidim::Components::BaseController
      helper Decidim::Messaging::ConversationHelper

      helper_method :participation_limit_reached?

      private

      def participation_limit
        return nil if component_settings.participation_limit.zero?
        component_settings.participation_limit
      end

      def participation_limit_reached?
        return false unless participation_limit

        participations.where(author: current_user).count >= participation_limit
      end

      def participations
        Participation.where(component: current_component)
      end
    end
  end
end
