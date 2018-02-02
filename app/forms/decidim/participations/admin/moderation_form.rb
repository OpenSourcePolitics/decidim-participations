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

        validates :sqr_status, presence: true, if: ->(form) { form.sqr_status } # sqr_status is needed when participation is moderated but not when its answer is moderated.
      end
    end
  end
end
