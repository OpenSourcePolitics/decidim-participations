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
        attribute :justification

        validates :justification, presence: true, if: ->(form) { form.state == "incomplete" }
      end
    end
  end
end
