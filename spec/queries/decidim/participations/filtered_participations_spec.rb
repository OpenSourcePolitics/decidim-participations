# frozen_string_literal: true

require "spec_helper"

describe Decidim::Participations::FilteredParticipations do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:feature) { create(:participation_feature, participatory_space: participatory_process) }
  let(:another_feature) { create(:participation_feature, participatory_space: participatory_process) }

  let(:participations) { create_list(:participation, 3, feature: feature) }
  let(:old_participations) { create_list(:participation, 3, feature: feature, created_at: 10.days.ago) }
  let(:another_participations) { create_list(:participation, 3, feature: another_feature) }

  it "returns participations included in a collection of features" do
    expect(described_class.for([feature, another_feature])).to match_array participations.concat(old_participations, another_participations)
  end

  it "returns participations created in a date range" do
    expect(described_class.for([feature, another_feature], 2.weeks.ago, 1.week.ago)).to match_array old_participations
  end
end
