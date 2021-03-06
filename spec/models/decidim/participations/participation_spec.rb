# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe Participation do
      subject { participation }

      let(:participation) { build(:participation, feature: feature) }
      let(:organization) { feature.participatory_space.organization }
      let(:feature) { build :participation_feature }

      include_examples "authorable"
      include_examples "has feature"
      include_examples "has scope"
      include_examples "has category"
      include_examples "has reference"
      include_examples "reportable"

      it { is_expected.to be_valid }

      it "has a votes association returning participation votes" do
        expect(subject.votes.count).to eq(0)
      end

      describe "#voted_by?" do
        let(:user) { create(:user, organization: subject.organization) }

        it "returns false if the participation is not voted by the given user" do
          expect(subject).not_to be_voted_by(user)
        end

        it "returns true if the participation is not voted by the given user" do
          create(:participation_vote, participation: subject, author: user)
          expect(subject).to be_voted_by(user)
        end
      end

      context "when it has been accepted" do
        let(:participation) { build(:participation, :accepted) }

        it { is_expected.to be_answered }
        it { is_expected.to be_accepted }
      end

      context "when it has been rejected" do
        let(:participation) { build(:participation, :rejected) }

        it { is_expected.to be_answered }
        it { is_expected.to be_rejected }
      end

      describe "#users_to_notify_on_comment_authorized" do
        let!(:follows) { create_list(:follow, 3, followable: subject) }
        let(:followers) { follows.map(&:user) }
        let(:participatory_space) { subject.feature.participatory_space }
        let(:organization) { participatory_space.organization }
        let!(:participatory_process_admin) do
          user = create(:user, :confirmed, organization: organization)
          Decidim::ParticipatoryProcessUserRole.create!(
            role: :admin,
            user: user,
            participatory_process: participatory_space
          )
          user
        end

        context "when the participation is official" do
          let(:participation) { build(:participation, :official) }

          it "returns the followers and the feature's participatory space admins" do
            expect(subject.users_to_notify_on_comment_authorized).to match_array(followers.concat([participatory_process_admin]))
          end
        end

        context "when the participation is not official" do
          it "returns the followers" do
            expect(subject.users_to_notify_on_comment_authorized).to match_array(followers)
          end
        end
      end

      describe "#maximum_votes" do
        let(:maximum_votes) { 10 }

        context "when the feature's settings are set to an integer bigger than 0" do
          before do
            feature[:settings]["global"] = { maximum_votes_per_participation: 10 }
            feature.save!
          end

          it "returns the maximum amount of votes for this participation" do
            expect(participation.maximum_votes).to eq(10)
          end
        end

        context "when the feature's settings are set to 0" do
          before do
            feature[:settings]["global"] = { maximum_votes_per_participation: 0 }
            feature.save!
          end

          it "returns nil" do
            expect(participation.maximum_votes).to be_nil
          end
        end
      end

      describe "#editable_by?" do
        let(:author) { build(:user, organization: organization) }

        context "when user is author" do
          let(:participation) { build :participation, feature: feature, author: author, created_at: Time.current }

          it { is_expected.to be_editable_by(author) }
        end

        context "when participation is from user group and user is admin" do
          let(:user_group) { create :user_group, users: [author], organization: author.organization }
          let(:participation) { build :participation, feature: feature, author: author, created_at: Time.current, user_group: user_group }

          it { is_expected.to be_editable_by(author) }
        end

        context "when user is not the author" do
          let(:participation) { build :participation, feature: feature, created_at: Time.current }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when participation is answered" do
          let(:participation) { build :participation, :with_answer, feature: feature, created_at: Time.current, author: author }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when participation editing time has run out" do
          let(:participation) { build :participation, created_at: 10.minutes.ago, feature: feature, author: author }

          it { is_expected.not_to be_editable_by(author) }
        end
      end
    end
  end
end
