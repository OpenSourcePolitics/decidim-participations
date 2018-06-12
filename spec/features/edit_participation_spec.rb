# frozen_string_literal: true

require "spec_helper"

describe "Edit participations", type: :component do
  include_context "with a component"
  let(:manifest_name) { "participations" }

  let!(:user) { create :user, :confirmed, organization: participatory_process.organization }
  let!(:another_user) { create :user, :confirmed, organization: participatory_process.organization }
  let!(:participation) { create :participation, author: user, component: component }

  before do
    switch_to_host user.organization.host
  end

  describe "editing my own participation" do
    let(:new_title) { "This is my participation new title" }
    let(:new_body) { "This is my participation new body" }

    before do
      login_as user, scope: :user
    end

    it "can be updated" do
      visit_component

      click_link participation.title
      click_link "Edit participation"

      expect(page).to have_content "EDIT PROPOSAL"

      fill_in "Title", with: new_title
      fill_in "Body", with: new_body
      click_button "Send"

      expect(page).to have_content(new_title)
      expect(page).to have_content(new_body)
    end

    context "when updating with wrong data" do
      let(:component) { create(:participation_component, :with_creation_enabled, :with_attachments_allowed, participatory_space: participatory_process) }

      it "returns an error message" do
        visit_component

        click_link participation.title
        click_link "Edit participation"

        expect(page).to have_content "EDIT PROPOSAL"

        fill_in "Body", with: "A"
        click_button "Send"

        expect(page).to have_content("Is using too much caps, Is too short, Is using too much caps, Is too short")
      end
    end
  end

  describe "editing someone else's participation" do
    before do
      login_as another_user, scope: :user
    end

    it "renders an error" do
      visit_component

      click_link participation.title
      expect(page).to have_no_content("Edit participation")
      visit current_path + "/edit"

      expect(page).to have_content("not authorized")
    end
  end

  describe "editing my participation outside the time limit" do
    let!(:participation) { create :participation, author: user, component: component, created_at: 1.hour.ago }

    before do
      login_as another_user, scope: :user
    end

    it "renders an error" do
      visit_component

      click_link participation.title
      expect(page).to have_no_content("Edit participation")
      visit current_path + "/edit"

      expect(page).to have_content("not authorized")
    end
  end
end
