# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe ParticipationVote do
      subject { participation_vote }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "participations") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, organization: organization) }
      let!(:participation) { create(:participation, component: component, author: author) }
      let!(:participation_vote) { build(:participation_vote, participation: participation, author: author) }

      it "is valid" do
        expect(participation_vote).to be_valid
      end

      it "has an associated author" do
        expect(participation_vote.author).to be_a(Decidim::User)
      end

      it "has an associated participation" do
        expect(participation_vote.participation).to be_a(Decidim::Participations::Participation)
      end

      it "validates uniqueness for author and participation combination" do
        participation_vote.save!
        expect do
          create(:participation_vote, participation: participation, author: author)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "when no author" do
        before do
          participation_vote.author = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when no participation" do
        before do
          participation_vote.participation = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when participation and author have different organization" do
        let(:other_author) { create(:user) }
        let(:other_participation) { create(:participation) }

        it "is invalid" do
          participation_vote = build(:participation_vote, participation: other_participation, author: other_author)
          expect(participation_vote).to be_invalid
        end
      end

      context "when participation is rejected" do
        let!(:participation) { create(:participation, :rejected, component: component, author: author) }

        it { is_expected.to be_invalid }
      end
    end
  end
end
