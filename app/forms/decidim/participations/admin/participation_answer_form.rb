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

        attr_accessor :the_recipient_role

        def current_user_is_moa?
          process_role = ParticipatoryProcessUserRole.where(user: current_user).first
          process_role.present? && process_role.role == "moa"
        end

         def current_user_is_cpdp?
          ParticipatoryProcessUserRole.where(user: current_user).first.role == "cpdp"
        end

        def cpdp_answering_cpdp?
          ParticipatoryProcessUserRole.where(user: current_user).first.role == "cpdp" and form.the_recipient_role == "cpdp"
        end
        
      end
    end
  end
end
