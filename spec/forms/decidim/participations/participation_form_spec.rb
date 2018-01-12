# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe ParticipationForm do
      let(:params) do
        super.merge(
          user_group_id: user_group_id
        )
      end

      it_behaves_like "a participation form"
    end
  end
end
