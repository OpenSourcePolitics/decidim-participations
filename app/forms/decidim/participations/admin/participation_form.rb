# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      # A form object to be used when admin users want to create a participation.
      class ParticipationForm < Decidim::Form
        mimic :participation

        attribute :body, String
        attribute :original_body, String
        attribute :participation_type, String
        attribute :recipient_role, String
        attribute :category_id, Integer
        attribute :moderation, ModerationForm

        validates :participation_type, :moderation, presence: true
        validates :recipient_role, presence: true, if: ->(form) { form.participation_type == "question" }

        validates :category, presence: true, if: ->(form) { form.category_id.present? }
        delegate :categories, to: :current_feature

        def map_model(model)
          return unless model.categorization

          self.category_id = model.categorization.decidim_category_id
        end

        alias feature current_feature

        # Finds the Category from the category_id.
        #
        # Returns a Decidim::Category
        def category
          @category ||= categories.find_by(id: category_id)
        end

        # Finds the Scope from the given decidim_scope_id, uses participatory space scope if missing.
        #
        # Returns a Decidim::Scope
        def scope
          @scope ||= @scope_id ? current_feature.scopes.find_by(id: @scope_id) : current_participatory_space&.scope
        end

        # Scope identifier
        #
        # Returns the scope identifier related to the participation
        def scope_id
          @scope_id || scope&.id
        end
      end
    end
  end
end
