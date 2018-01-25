# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      # A form object to be used when admin users want to create a moderation.
      class ModerationForm < Decidim::Form
        mimic :moderation

        attribute :justification, String
        attribute :sqr_status, String
        attribute :id, Integer
      end
    end
  end
end
