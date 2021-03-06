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


        # sqr_status is needed only on the edit view, not the answer view.
        attr_accessor :on_the_answer_page

        validates :sqr_status, presence: true, unless: ->(form) { form.on_the_answer_page == "yes" }
      end
    end
  end
end
