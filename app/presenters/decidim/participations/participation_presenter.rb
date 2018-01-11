# frozen_string_literal: true

module Decidim
  module Participations
    #
    # Decorator for participations
    #
    class ParticipationPresenter < SimpleDelegator
      def author
        @author ||= if official?
                      Decidim::Participations::OfficialAuthorPresenter.new
                    elsif user_group
                      Decidim::UserGroupPresenter.new(user_group)
                    else
                      Decidim::UserPresenter.new(super)
                    end
      end
    end
  end
end
