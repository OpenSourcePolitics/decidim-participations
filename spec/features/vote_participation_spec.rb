# frozen_string_literal: true

require "spec_helper"

describe "Vote Participation", type: :feature do
  include_context "with a feature"
  let(:manifest_name) { "participations" }

  let!(:participations) { create_list(:participation, 3, feature: feature) }
  let!(:participation) { Decidim::Participations::Participation.where(feature: feature).first }
  let!(:user) { create :user, :confirmed, organization: organization }

  def expect_page_not_to_include_votes
    expect(page).to have_no_button("Vote")
    expect(page).to have_no_css(".card__support__data span", text: "0 VOTES")
  end

  context "when votes are not enabled" do
    context "when the user is not logged in" do
      it "doesn't show the vote participation button and counts" do
        visit_feature
        expect_page_not_to_include_votes

        click_link participation.title
        expect_page_not_to_include_votes
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      it "doesn't show the vote participation button and counts" do
        visit_feature
        expect_page_not_to_include_votes

        click_link participation.title
        expect_page_not_to_include_votes
      end
    end
  end

  context "when votes are blocked" do
    let!(:feature) do
      create(:participation_feature,
             :with_votes_blocked,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    it "shows the vote count and the vote button is disabled" do
      visit_feature
      expect_page_not_to_include_votes
    end
  end

  context "when votes are enabled" do
    let!(:feature) do
      create(:participation_feature,
             :with_votes_enabled,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    context "when the user is not logged in" do
      it "is given the option to sign in" do
        visit_feature

        within ".card__support", match: :first do
          click_button "Vote"
        end

        expect(page).to have_css("#loginModal", visible: true)
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      context "when the participation is not voted yet" do
        before do
          visit_feature
        end

        it "is able to vote the participation" do
          within "#participation-#{participation.id}-vote-button" do
            click_button "Vote"
            expect(page).to have_button("Already voted")
          end

          within "#participation-#{participation.id}-votes-count" do
            expect(page).to have_content("1 VOTE")
          end
        end
      end

      context "when the participation is already voted" do
        before do
          create(:participation_vote, participation: participation, author: user)
          visit_feature
        end

        it "is not able to vote it again" do
          within "#participation-#{participation.id}-vote-button" do
            expect(page).to have_button("Already voted")
            expect(page).to have_no_button("Vote")
          end

          within "#participation-#{participation.id}-votes-count" do
            expect(page).to have_content("1 VOTE")
          end
        end

        it "is able to undo the vote" do
          within "#participation-#{participation.id}-vote-button" do
            click_button "Already voted"
            expect(page).to have_button("Vote")
          end

          within "#participation-#{participation.id}-votes-count" do
            expect(page).to have_content("0 VOTES")
          end
        end
      end

      context "when the feature has a vote limit" do
        let(:vote_limit) { 10 }

        let!(:feature) do
          create(:participation_feature,
                 :with_votes_enabled,
                 :with_vote_limit,
                 vote_limit: vote_limit,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        describe "vote counter" do
          context "when votes are blocked" do
            let!(:feature) do
              create(:participation_feature,
                     :with_votes_blocked,
                     :with_vote_limit,
                     vote_limit: vote_limit,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "doesn't show the remaining votes counter" do
              visit_feature

              expect(page).to have_css(".voting-rules")
              expect(page).to have_no_css(".remaining-votes-counter")
            end
          end

          context "when votes are enabled" do
            let!(:feature) do
              create(:participation_feature,
                     :with_votes_enabled,
                     :with_vote_limit,
                     vote_limit: vote_limit,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "shows the remaining votes counter" do
              visit_feature

              expect(page).to have_css(".voting-rules")
              expect(page).to have_css(".remaining-votes-counter")
            end
          end
        end

        context "when the participation is not voted yet" do
          before do
            visit_feature
          end

          it "updates the remaining votes counter" do
            within "#participation-#{participation.id}-vote-button" do
              click_button "Vote"
              expect(page).to have_button("Already voted")
            end

            expect(page).to have_content("REMAINING 9 VOTES")
          end
        end

        context "when the participation is not voted yet but the user isn't authorized" do
          before do
            permissions = {
              vote: {
                authorization_handler_name: "dummy_authorization_handler"
              }
            }

            feature.update_attributes!(permissions: permissions)
            visit_feature
          end

          it "shows a modal dialog" do
            within "#participation-#{participation.id}-vote-button" do
              click_button "Vote"
            end

            expect(page).to have_content("Authorization required")
          end
        end

        context "when the participation is already voted" do
          before do
            create(:participation_vote, participation: participation, author: user)
            visit_feature
          end

          it "is not able to vote it again" do
            within "#participation-#{participation.id}-vote-button" do
              expect(page).to have_button("Already voted")
              expect(page).to have_no_button("Vote")
            end
          end

          it "is able to undo the vote" do
            within "#participation-#{participation.id}-vote-button" do
              click_button "Already voted"
              expect(page).to have_button("Vote")
            end

            within "#participation-#{participation.id}-votes-count" do
              expect(page).to have_content("0 VOTES")
            end

            expect(page).to have_content("REMAINING 10 VOTES")
          end
        end

        context "when the user has reached the votes limit" do
          let(:vote_limit) { 1 }

          before do
            create(:participation_vote, participation: participation, author: user)
            visit_feature
          end

          it "is not able to vote other participations" do
            expect(page).to have_css(".card__button[disabled]", count: 2)
          end

          context "when votes are blocked" do
            let!(:feature) do
              create(:participation_feature,
                     :with_votes_blocked,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "shows the vote count but not the vote button" do
              expect(page).to have_css(".card__support__data", text: "1 VOTE")
              expect(page).to have_content("Voting disabled")
            end
          end
        end
      end
    end

    context "when the participation is rejected" do
      let!(:rejected_participation) { create(:participation, :rejected, feature: feature) }

      before do
        feature.update_attributes!(settings: { participation_answering_enabled: true })
      end

      it "cannot be voted" do
        visit_feature
        expect(page).not_to have_selector("#participation-#{rejected_participation.id}-vote-button")

        click_link rejected_participation.title
        expect(page).not_to have_selector("#participation-#{rejected_participation.id}-vote-button")
      end
    end

    context "when participations have a voting limit" do
      let!(:feature) do
        create(:participation_feature,
               :with_votes_enabled,
               :with_maximum_votes_per_participation,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "doesn't allow users to vote to a participation that's reached the limit" do
        create(:participation_vote, participation: participation)
        visit_feature

        participation_element = page.find("article", text: participation.reference)

        within participation_element do
          within ".card__support", match: :first do
            expect(page).to have_content("Vote limit reached")
          end
        end
      end

      it "allows users to vote on participations under the limit" do
        visit_feature

        participation_element = page.find("article", text: participation.reference)

        within participation_element do
          within ".card__support", match: :first do
            click_button "Vote"
            expect(page).to have_content("Already voted")
          end
        end
      end
    end
  end
end
