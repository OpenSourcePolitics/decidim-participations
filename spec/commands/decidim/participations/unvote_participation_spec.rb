# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe UnvoteParticipation do
      describe "call" do
        let(:participation) { create(:participation) }
        let(:current_user) { create(:user, organization: participation.component.organization) }
        let!(:participation_vote) { create(:participation_vote, author: current_user, participation: participation) }
        let(:command) { described_class.new(participation, current_user) }

        it "broadcasts ok" do
          expect { command.call }.to broadcast(:ok)
        end

        it "deletes the participation vote for that user" do
          expect do
            command.call
          end.to change { ParticipationVote.count }.by(-1)
        end
      end
    end
  end
end
