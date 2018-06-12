# frozen_string_literal: true

require "spec_helper"

describe "Participations component" do # rubocop:disable RSpec/DescribeClass
  let!(:component) { create(:participation_component) }

  describe "on destroy" do
    context "when there are no participations for the component" do
      it "destroys the component" do
        expect do
          Decidim::Admin::DestroyComponent.call(component)
        end.to change { Decidim::Component.count }.by(-1)

        expect(component).to be_destroyed
      end
    end

    context "when there are participations for the component" do
      before do
        create(:participation, component: component)
      end

      it "raises an error" do
        expect do
          Decidim::Admin::DestroyComponent.call(component)
        end.to broadcast(:invalid)

        expect(component).not_to be_destroyed
      end
    end
  end

  describe "stats" do
    subject { current_stat[2] }

    let(:raw_stats) do
      Decidim.component_manifests.map do |component_manifest|
        component_manifest.stats.filter(name: stats_name).with_context(component).flat_map { |name, data| [component_manifest.name, name, data] }
      end
    end

    let(:stats) do
      raw_stats.select { |stat| stat[0] == :participations }
    end

    let!(:participation) { create :participation }
    let(:component) { participation.component }
    let!(:hidden_participation) { create :participation, component: component }
    let!(:moderation) { create :moderation, reportable: hidden_participation, hidden_at: 1.day.ago }

    let(:current_stat) { stats.find { |stat| stat[1] == stats_name } }

    describe "participations_count" do
      let(:stats_name) { :participations_count }

      it "only counts not hidden participations" do
        expect(Decidim::Participations::Participation.where(component: component).count).to eq 2
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
