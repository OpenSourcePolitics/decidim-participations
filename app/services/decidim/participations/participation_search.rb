# frozen_string_literal: true

module Decidim
  module Participations
    # A service to encapsualte all the logic when searching and filtering
    # participations in a participatory process.
    class ParticipationSearch < ResourceSearch
      # Public: Initializes the service.
      # component     - A Decidim::Component to get the participations from.
      # page        - The page number to paginate the results.
      # per_page    - The number of participations to return per page.
      def initialize(options = {})
        super(Participation.all, options)
      end

      # Handle the search_text filter
      def search_search_text
        query
          .where("title ILIKE ?", "%#{search_text}%")
          .or(query.where("body ILIKE ?", "%#{search_text}%"))
      end

      # Handle the origin filter
      # The 'official' participations doesn't have an author id
      def search_origin
        if origin == "official"
          query.where(decidim_author_id: nil)
        elsif origin == "citizens"
          query.where.not(decidim_author_id: nil)
        else # Assume 'all'
          query
        end
      end

      # Handle the type filter
      def search_participation_type
        if participation_type == "all"
          query
        else
          query.where(participation_type: participation_type)
        end
      end

      # Handle the activity filter
      def search_activity
        if activity.include? "voted"
          query
            .includes(:votes)
            .where(decidim_participations_participation_votes: {
                     decidim_author_id: options[:current_user]
                   })
        else
          query
        end
      end

      # Handle the state filter
      def search_state
        if state == "all"
          query
        else
          get_query(participation_type, state, query)
        end
      end

      # Filters Participations by the name of the classes they are linked to. By default,
      # returns all Participations. When a `related_to` param is given, then it camelcases item
      # to find the real class name and checks the links for the Participations.
      #
      # The `related_to` param is expected to be in this form:
      #
      #   "decidim/meetings/meeting"
      #
      # This can be achieved by performing `klass.name.underscore`.
      #
      # Returns only those participations that are linked to the given class name.
      def search_related_to
        from = query
               .joins(:resource_links_from)
               .where(decidim_resource_links: { to_type: related_to.camelcase })

        to = query
             .joins(:resource_links_to)
             .where(decidim_resource_links: { from_type: related_to.camelcase })

        query.where(id: from).or(query.where(id: to))
      end

      private

      # The state are set when user is making search for questions, then it'll be present as long as the page won't be reload. As we don't want chaining filter for contributions and opinions we have to make the request without the state argument.
      def get_query(participation_type, state, query)
        if participation_type == "question"
          query.where(state: state, participation_type: participation_type)
        else
          query
        end
      end
    end
  end
end
