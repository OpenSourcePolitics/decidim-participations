# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe VoteParticipation do
      describe "call" do
        let(:participation) { create(:participation) }
        let(:current_user) { create(:user, organization: participation.component.organization) }
        let(:command) { described_class.new(participation, current_user) }

        context "with normal conditions" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates a new vote for the participation" do
            expect do
              command.call
            end.to change { ParticipationVote.count }.by(1)
          end
        end

        context "when the vote is not valid" do
          before do
            # rubocop:disable RSpec/AnyInstance
            allow_any_instance_of(ParticipationVote).to receive(:valid?).and_return(false)
            # rubocop:enable RSpec/AnyInstance
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "doesn't create a new vote for the participation" do
            expect do
              command.call
            end.to change { ParticipationVote.count }.by(0)
          end
        end

        context "when the maximum votes have been reached" do
          before do
            expect(participation).to receive(:maximum_votes_reached?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end
      end
    end
  end
end
