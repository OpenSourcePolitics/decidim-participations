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
        attribute :moderation, ModerationForm

        validates :state, presence: true, unless: :current_user_is_moa?

        def current_user_is_moa?
          process_role = ParticipatoryProcessUserRole.where(user: current_user).first
          process_role.present? && process_role.role == "moa"
        end
      end
    end
  end
end
