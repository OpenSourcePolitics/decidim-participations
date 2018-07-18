# frozen_string_literal: true

require "spec_helper"

describe "Comments", type: :component do
  let!(:component) { create(:participation_component, organization: organization) }
  let!(:author) { create(:user, :confirmed, organization: organization) }
  let!(:commentable) { create(:participation, component: component, author: author) }

  let(:resource_path) { resource_locator(commentable).path }

  include_examples "comments"
end
