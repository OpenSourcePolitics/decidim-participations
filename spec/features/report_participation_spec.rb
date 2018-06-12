# frozen_string_literal: true

require "spec_helper"

describe "Report Participation", type: :component do
  include_context "with a component"

  let(:manifest_name) { "participations" }
  let!(:participations) { create_list(:participation, 3, component: component) }
  let(:reportable) { participations.first }
  let(:reportable_path) { resource_locator(reportable).path }
  let!(:user) { create :user, :confirmed, organization: organization }

  let!(:component) do
    create(:participation_component,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  include_examples "reports"
end
