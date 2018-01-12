# frozen_string_literal: true

require "spec_helper"

describe "Comments", type: :feature do
  let!(:feature) { create(:participation_feature, organization: organization) }
  let!(:author) { create(:user, :confirmed, organization: organization) }
  let!(:commentable) { create(:participation, feature: feature, author: author) }

  let(:resource_path) { resource_locator(commentable).path }

  include_examples "comments"
end
