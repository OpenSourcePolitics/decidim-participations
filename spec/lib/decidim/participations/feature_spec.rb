# frozen_string_literal: true

require "spec_helper"

describe "Participations feature" do # rubocop:disable RSpec/DescribeClass
  let!(:feature) { create(:participation_feature) }

  describe "on destroy" do
    context "when there are no participations for the feature" do
      it "destroys the feature" do
        expect do
          Decidim::Admin::DestroyFeature.call(feature)
        end.to change { Decidim::Feature.count }.by(-1)

        expect(feature).to be_destroyed
      end
    end

    context "when there are participations for the feature" do
      before do
        create(:participation, feature: feature)
      end

      it "raises an error" do
        expect do
          Decidim::Admin::DestroyFeature.call(feature)
        end.to broadcast(:invalid)

        expect(feature).not_to be_destroyed
      end
    end
  end

  describe "stats" do
    subject { current_stat[2] }

    let(:raw_stats) do
      Decidim.feature_manifests.map do |feature_manifest|
        feature_manifest.stats.filter(name: stats_name).with_context(feature).flat_map { |name, data| [feature_manifest.name, name, data] }
      end
    end

    let(:stats) do
      raw_stats.select { |stat| stat[0] == :participations }
    end

    let!(:participation) { create :participation }
    let(:feature) { participation.feature }
    let!(:hidden_participation) { create :participation, feature: feature }
    let!(:moderation) { create :moderation, reportable: hidden_participation, hidden_at: 1.day.ago }

    let(:current_stat) { stats.find { |stat| stat[1] == stats_name } }

    describe "participations_count" do
      let(:stats_name) { :participations_count }

      it "only counts not hidden participations" do
        expect(Decidim::Participations::Participation.where(feature: feature).count).to eq 2
        expect(subject).to eq 1
      end
    end

    describe "votes_count" do
      let(:stats_name) { :votes_count }

      before do
        create_list :participation_vote, 2, participation: participation
        create_list :participation_vote, 3, participation: hidden_participation
      end

      it "counts the votes from visible participations" do
        expect(Decidim::Participations::ParticipationVote.count).to eq 5
        expect(subject).to eq 2
      end
    end

    describe "comments_count" do
      let(:stats_name) { :comments_count }

      before do
        create_list :comment, 2, commentable: participation
        create_list :comment, 3, commentable: hidden_participation
      end

      it "counts the comments from visible participations" do
        expect(Decidim::Comments::Comment.count).to eq 5
        expect(subject).to eq 2
      end
    end
  end
end
