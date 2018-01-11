# frozen_string_literal: true

module Decidim
  module Participations
    #
    # A dummy presenter to abstract out the author of an official participation.
    #
    class OfficialAuthorPresenter
      def name
        I18n.t("decidim.participations.models.participation.fields.official_participation")
      end

      def nickname
        ""
      end

      def badge
        ""
      end

      def profile_path
        ""
      end

      def avatar_url
        ActionController::Base.helpers.asset_path("decidim/default-avatar.svg")
      end

      def deleted?
        false
      end
    end
  end
end
