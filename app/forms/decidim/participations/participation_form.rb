# frozen_string_literal: true

module Decidim
  module Participations
    # A form object to be used when public users want to create a participation.
    class ParticipationForm < Decidim::Form
      mimic :participation

      attribute :body, String
      attribute :address, String
      attribute :latitude, Float
      attribute :longitude, Float
      attribute :participation_type, String
      attribute :category_id, Integer
      attribute :scope_id, Integer
      attribute :user_group_id, Integer
      attribute :has_address, Boolean
      attribute :attachment_title, String
      attribute :attachment, AttachmentForm

      validates :body, presence: true, etiquette: true
      validates :body, length: { maximum: 2000 }, etiquette: true
      validates :address, geocoding: true, if: ->(form) { Decidim.geocoder.present? && form.has_address? }
      validates :address, presence: true, if: ->(form) { form.has_address? }
      validates :participation_type, presence: true
      validates :category, presence: true, if: ->(form) { form.category_id.present? }
      validates :scope, presence: true, if: ->(form) { form.scope_id.present? }
      validate { errors.add(:scope_id, :invalid) if current_participatory_space&.scope && !current_participatory_space&.scope&.ancestor_of?(scope) }

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

      def has_address?
        current_feature.settings.geocoding_enabled? && has_address
      end
    end
  end
end
