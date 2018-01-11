# frozen_string_literal: true

require "spec_helper"

describe "Admin manages participations", type: :feature do
  let(:manifest_name) { "participations" }
  let!(:participation) { create :participation, feature: current_feature }
  let!(:reportables) { create_list(:participation, 3, feature: current_feature) }

  include_context "when managing a feature as an admin"

  it_behaves_like "manage participations"
  it_behaves_like "manage moderations"
  it_behaves_like "export participations"
  it_behaves_like "manage announcements"
  it_behaves_like "manage participations help texts"
end
