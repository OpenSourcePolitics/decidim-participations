# frozen_string_literal: true

require "spec_helper"

describe Decidim::Participations::FilteredParticipations do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:component) { create(:participation_component, participatory_space: participatory_process) }
  let(:another_component) { create(:participation_component, participatory_space: participatory_process) }

  let(:participations) { create_list(:participation, 3, component: component) }
  let(:old_participations) { create_list(:participation, 3, component: component, created_at: 10.days.ago) }
  let(:another_participations) { create_list(:participation, 3, component: another_component) }

  it "returns participations included in a collection of components" do
    expect(described_class.for([component, another_component])).to match_array participations.concat(old_participations, another_participations)
  end

  it "returns participations created in a date range" do
    expect(described_class.for([component, another_component], 2.weeks.ago, 1.week.ago)).to match_array old_participations
  end
end
