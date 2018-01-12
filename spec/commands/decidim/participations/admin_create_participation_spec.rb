# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    module Admin
      describe CreateParticipation do
        let(:form_klass) { ParticipationForm }

        it_behaves_like "create a participation", false
      end
    end
  end
end
