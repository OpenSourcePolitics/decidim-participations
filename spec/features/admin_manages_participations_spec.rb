# frozen_string_literal: true

require "spec_helper"

describe "Admin manages participations", type: :component do
  let(:manifest_name) { "participations" }
  let!(:participation) { create :participation, component: current_component }
  let!(:reportables) { create_list(:participation, 3, component: current_component) }

  include_context "when managing a component as an admin"

  it_behaves_like "manage participations"
  it_behaves_like "manage moderations"
  it_behaves_like "export participations"
  it_behaves_like "manage announcements"
  it_behaves_like "manage participations help texts"
end
