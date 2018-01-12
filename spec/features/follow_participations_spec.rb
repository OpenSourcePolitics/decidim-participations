# frozen_string_literal: true

require "spec_helper"

describe "Follow participations", type: :feature do
  let(:manifest_name) { "participations" }

  let!(:followable) do
    create(:participation, feature: feature)
  end

  include_examples "follows"
end
