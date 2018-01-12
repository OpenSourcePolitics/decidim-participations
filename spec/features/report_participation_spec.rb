# frozen_string_literal: true

require "spec_helper"

describe "Report Participation", type: :feature do
  include_context "with a feature"

  let(:manifest_name) { "participations" }
  let!(:participations) { create_list(:participation, 3, feature: feature) }
  let(:reportable) { participations.first }
  let(:reportable_path) { resource_locator(reportable).path }
  let!(:user) { create :user, :confirmed, organization: organization }

  let!(:feature) do
    create(:participation_feature,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  include_examples "reports"
end
