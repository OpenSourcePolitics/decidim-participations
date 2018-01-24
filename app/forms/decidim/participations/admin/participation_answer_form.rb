# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      # A form object to be used when admin users want to answer a participation.
      class ParticipationAnswerForm < Decidim::Form
        include TranslatableAttributes
        mimic :participation_answer

        translatable_attribute :answer, String
        attribute :state, String
        # attribute :justification, String

        # validates :state, presence: true, inclusion: { in: %w(accepted rejected evaluating) }
        validates :justification, translatable_presence: true, if: ->(form) { form.state == "rejected" }
      end
    end
  end
end
