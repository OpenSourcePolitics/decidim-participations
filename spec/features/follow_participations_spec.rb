# frozen_string_literal: true

require "spec_helper"

describe "Follow participations", type: :component do
  let(:manifest_name) { "participations" }

  let!(:followable) do
    create(:participation, component: component)
  end

  include_examples "follows"
end
