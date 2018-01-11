# frozen_string_literal: true

require "spec_helper"

describe "Participations", type: :feature do
  include_context "with a feature"
  let(:manifest_name) { "participations" }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }

  before do
    Geocoder::Lookup::Test.add_stub(
      address,
      [{ "latitude" => latitude, "longitude" => longitude }]
    )
  end

  matcher :have_author do |name|
    match { |node| node.has_selector?(".author-data", text: name) }
    match_when_negated { |node| node.has_no_selector?(".author-data", text: name) }
  end

  context "when creating a new participation" do
    let(:scope_picker) { scopes_picker_find(:participation_scope_id) }

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      context "with creation enabled" do
        let!(:feature) do
          create(:participation_feature,
                 :with_creation_enabled,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        context "when process is not related to any scope" do
          it "can be related to a scope" do
            visit_feature
            click_link "New participation"

            within "form.new_participation" do
              expect(page).to have_content(/Scope/i)
            end
          end
        end

        context "when process is related to a leaf scope" do
          let(:participatory_process) { scoped_participatory_process }

          it "cannot be related to a scope" do
            visit_feature
            click_link "New participation"

            within "form.new_participation" do
              expect(page).to have_no_content("Scope")
            end
          end
        end

        it "creates a new participation", :slow do
          visit_feature

          click_link "New participation"

          within ".new_participation" do
            fill_in :participation_title, with: "Oriol for president"
            fill_in :participation_body, with: "He will solve everything"
            select translated(category.name), from: :participation_category_id
            scope_pick scope_picker, scope

            find("*[type=submit]").click
          end

          expect(page).to have_content("successfully")
          expect(page).to have_content("Oriol for president")
          expect(page).to have_content("He will solve everything")
          expect(page).to have_content(translated(category.name))
          expect(page).to have_content(translated(scope.name))
          expect(page).to have_author(user.name)
        end

        context "when geocoding is enabled", :serves_map do
          let!(:feature) do
            create(:participation_feature,
                   :with_creation_enabled,
                   :with_geocoding_enabled,
                   manifest: manifest,
                   participatory_space: participatory_process)
          end

          it "creates a new participation", :slow do
            visit_feature

            click_link "New participation"

            within ".new_participation" do
              fill_in :participation_title, with: "Oriol for president"
              fill_in :participation_body, with: "He will solve everything"

              check :participation_has_address

              fill_in :participation_address, with: address
              select translated(category.name), from: :participation_category_id
              scope_pick scope_picker, scope

              find("*[type=submit]").click
            end

            expect(page).to have_content("successfully")
            expect(page).to have_content("Oriol for president")
            expect(page).to have_content("He will solve everything")
            expect(page).to have_content(address)
            expect(page).to have_content(translated(category.name))
            expect(page).to have_content(translated(scope.name))
            expect(page).to have_author(user.name)
          end
        end

        context "when the user has verified organizations" do
          let(:user_group) { create(:user_group, :verified) }

          before do
            create(:user_group_membership, user: user, user_group: user_group)
          end

          it "creates a new participation as a user group", :slow do
            visit_feature
            click_link "New participation"

            within ".new_participation" do
              fill_in :participation_title, with: "Oriol for president"
              fill_in :participation_body, with: "He will solve everything"
              select translated(category.name), from: :participation_category_id
              scope_pick scope_picker, scope
              select user_group.name, from: :participation_user_group_id

              find("*[type=submit]").click
            end

            expect(page).to have_content("successfully")
            expect(page).to have_content("Oriol for president")
            expect(page).to have_content("He will solve everything")
            expect(page).to have_content(translated(category.name))
            expect(page).to have_content(translated(scope.name))
            expect(page).to have_author(user_group.name)
          end

          context "when geocoding is enabled", :serves_map do
            let!(:feature) do
              create(:participation_feature,
                     :with_creation_enabled,
                     :with_geocoding_enabled,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "creates a new participation as a user group", :slow do
              visit_feature
              click_link "New participation"

              within ".new_participation" do
                fill_in :participation_title, with: "Oriol for president"
                fill_in :participation_body, with: "He will solve everything"

                check :participation_has_address

                fill_in :participation_address, with: address
                select translated(category.name), from: :participation_category_id
                scope_pick scope_picker, scope
                select user_group.name, from: :participation_user_group_id

                find("*[type=submit]").click
              end

              expect(page).to have_content("successfully")
              expect(page).to have_content("Oriol for president")
              expect(page).to have_content("He will solve everything")
              expect(page).to have_content(address)
              expect(page).to have_content(translated(category.name))
              expect(page).to have_content(translated(scope.name))
              expect(page).to have_author(user_group.name)
            end
          end
        end

        context "when the user isn't authorized" do
          before do
            permissions = {
              create: {
                authorization_handler_name: "dummy_authorization_handler"
              }
            }

            feature.update_attributes!(permissions: permissions)
          end

          it "shows a modal dialog" do
            visit_feature
            click_link "New participation"
            expect(page).to have_content("Authorization required")
          end
        end

        context "when attachments are allowed", processing_uploads_for: Decidim::AttachmentUploader do
          let!(:feature) do
            create(:participation_feature,
                   :with_creation_enabled,
                   :with_attachments_allowed,
                   manifest: manifest,
                   participatory_space: participatory_process)
          end

          it "creates a new participation with attachments" do
            visit_feature

            click_link "New participation"

            within ".new_participation" do
              fill_in :participation_title, with: "Participation with attachments"
              fill_in :participation_body, with: "This is my participation and I want to upload attachments."
              fill_in :participation_attachment_title, with: "My attachment"
              attach_file :participation_attachment_file, Decidim::Dev.asset("city.jpeg")
              find("*[type=submit]").click
            end

            expect(page).to have_content("successfully")

            within ".section.images" do
              expect(page).to have_selector("img[src*=\"city.jpeg\"]", count: 1)
            end
          end
        end
      end

      context "when creation is not enabled" do
        it "does not show the creation button" do
          visit_feature
          expect(page).to have_no_link("New participation")
        end
      end

      context "when the participation limit is 1" do
        let!(:feature) do
          create(:participation_feature,
                 :with_creation_enabled,
                 :with_participation_limit,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        it "allows the creation of a single new participation" do
          visit_feature

          click_link "New participation"
          within ".new_participation" do
            fill_in :participation_title, with: "Creating my first and only participation"
            fill_in :participation_body, with: "This is my only participation's body and I'm using it unwisely."
            find("*[type=submit]").click
          end

          expect(page).to have_content("successfully")

          visit_feature

          click_link "New participation"
          within ".new_participation" do
            fill_in :participation_title, with: "Creating my second and impossible participation"
            fill_in :participation_body, with: "This is my only participation's body and I'm using it unwisely."
            find("*[type=submit]").click
          end

          expect(page).to have_no_content("successfully")
          expect(page).to have_css(".callout.alert", text: "limit")
        end
      end
    end
  end

  context "when viewing a single participation" do
    let!(:feature) do
      create(:participation_feature,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    let!(:participations) { create_list(:participation, 3, feature: feature) }

    it "allows viewing a single participation" do
      participation = participations.first

      visit_feature

      click_link participation.title

      expect(page).to have_content(participation.title)
      expect(page).to have_content(participation.body)
      expect(page).to have_author(participation.author.name)
      expect(page).to have_content(participation.reference)
    end

    context "when process is not related to any scope" do
      let!(:participation) { create(:participation, feature: feature, scope: scope) }

      it "can be filtered by scope" do
        visit_feature
        click_link participation.title
        expect(page).to have_content(translated(scope.name))
      end
    end

    context "when process is related to a child scope" do
      let!(:participation) { create(:participation, feature: feature, scope: scope) }
      let(:participatory_process) { scoped_participatory_process }

      it "does not show the scope name" do
        visit_feature
        click_link participation.title
        expect(page).to have_no_content(translated(scope.name))
      end
    end

    context "when it is an official participation" do
      let!(:official_participation) { create(:participation, feature: feature, author: nil) }

      it "shows the author as official" do
        visit_feature
        click_link official_participation.title
        expect(page).to have_content("Official participation")
      end
    end

    context "when a participation has comments" do
      let(:participation) { create(:participation, feature: feature) }
      let(:author) { create(:user, :confirmed, organization: feature.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: participation) }

      it "shows the comments" do
        visit_feature
        click_link participation.title

        comments.each do |comment|
          expect(page).to have_content(comment.body)
        end
      end
    end

    context "when a participation has been linked in a meeting" do
      let(:participation) { create(:participation, feature: feature) }
      let(:meeting_feature) do
        create(:feature, manifest_name: :meetings, participatory_space: participation.feature.participatory_space)
      end
      let(:meeting) { create(:meeting, feature: meeting_feature) }

      before do
        meeting.link_resources([participation], "participations_from_meeting")
      end

      it "shows related meetings" do
        visit_feature
        click_link participation.title

        expect(page).to have_i18n_content(meeting.title)
      end
    end

    context "when a participation has been linked in a result" do
      let(:participation) { create(:participation, feature: feature) }
      let(:dummy_feature) do
        create(:feature, manifest_name: :dummy, participatory_space: participation.feature.participatory_space)
      end
      let(:dummy_resource) { create(:dummy_resource, feature: dummy_feature) }

      before do
        dummy_resource.link_resources([participation], "included_participations")
      end

      it "shows related resources" do
        visit_feature
        click_link participation.title

        expect(page).to have_i18n_content(dummy_resource.title)
      end
    end

    context "when a participation is in evaluation" do
      let!(:participation) { create(:participation, :evaluating, :with_answer, feature: feature) }

      it "shows a badge and an answer" do
        visit_feature
        click_link participation.title

        expect(page).to have_content("Evaluating")

        within ".callout.secondary" do
          expect(page).to have_content("This participation is being evaluated")
          expect(page).to have_i18n_content(participation.answer)
        end
      end
    end

    context "when a participation has been rejected" do
      let!(:participation) { create(:participation, :rejected, :with_answer, feature: feature) }

      it "shows the rejection reason" do
        visit_feature
        click_link participation.title

        expect(page).to have_content("Rejected")

        within ".callout.warning" do
          expect(page).to have_content("This participation has been rejected")
          expect(page).to have_i18n_content(participation.answer)
        end
      end
    end

    context "when a participation has been accepted" do
      let!(:participation) { create(:participation, :accepted, :with_answer, feature: feature) }

      it "shows the acceptance reason" do
        visit_feature
        click_link participation.title

        expect(page).to have_content("Accepted")

        within ".callout.success" do
          expect(page).to have_content("This participation has been accepted")
          expect(page).to have_i18n_content(participation.answer)
        end
      end
    end

    context "when the participations'a author account has been deleted" do
      let(:participation) { participations.first }

      before do
        Decidim::DestroyAccount.call(participation.author, Decidim::DeleteAccountForm.from_params({}))
      end

      it "the user is displayed as a deleted user" do
        visit_feature

        click_link participation.title

        expect(page).to have_content("Deleted user")
      end
    end
  end

  context "when a participation has been linked in a project" do
    let(:feature) do
      create(:participation_feature,
             manifest: manifest,
             participatory_space: participatory_process)
    end
    let(:participation) { create(:participation, feature: feature) }
    let(:budget_feature) do
      create(:feature, manifest_name: :budgets, participatory_space: participation.feature.participatory_space)
    end
    let(:project) { create(:project, feature: budget_feature) }

    before do
      project.link_resources([participation], "included_participations")
    end

    it "shows related projects" do
      visit_feature
      click_link participation.title

      expect(page).to have_i18n_content(project.title)
    end
  end

  context "when listing participations in a participatory process" do
    shared_examples_for "a random participation ordering" do
      let!(:lucky_participation) { create(:participation, feature: feature) }
      let!(:unlucky_participation) { create(:participation, feature: feature) }

      it "lists the participations ordered randomly by default" do
        visit_feature

        expect(page).to have_selector("a", text: "Random")
        expect(page).to have_selector(".card--participation", count: 2)
        expect(page).to have_selector(".card--participation", text: lucky_participation.title)
        expect(page).to have_selector(".card--participation", text: unlucky_participation.title)
      end
    end

    it "lists all the participations" do
      create(:participation_feature,
             manifest: manifest,
             participatory_space: participatory_process)

      create_list(:participation, 3, feature: feature)

      visit_feature
      expect(page).to have_css(".card--participation", count: 3)
    end

    describe "default ordering" do
      it_behaves_like "a random participation ordering"
    end

    context "when voting phase is over" do
      let!(:feature) do
        create(:participation_feature,
               :with_votes_blocked,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      let!(:most_voted_participation) do
        participation = create(:participation, feature: feature)
        create_list(:participation_vote, 3, participation: participation)
        participation
      end

      let!(:less_voted_participation) { create(:participation, feature: feature) }

      before { visit_feature }

      it "lists the participations ordered by votes by default" do
        expect(page).to have_selector("a", text: "Most voted")
        expect(page).to have_selector("#participations .card-grid .column:first-child", text: most_voted_participation.title)
        expect(page).to have_selector("#participations .card-grid .column:last-child", text: less_voted_participation.title)
      end

      it "shows a disabled vote button for each participation, but no links to full participations" do
        expect(page).to have_button("Voting disabled", disabled: true, count: 2)
        expect(page).to have_no_link("View participation")
      end
    end

    context "when voting is disabled" do
      let!(:feature) do
        create(:participation_feature,
               :with_votes_disabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      describe "order" do
        it_behaves_like "a random participation ordering"
      end

      it "shows only links to full participations" do
        create_list(:participation, 2, feature: feature)

        visit_feature

        expect(page).to have_no_button("Voting disabled", disabled: true)
        expect(page).to have_no_button("Vote")
        expect(page).to have_link("View participation", count: 2)
      end
    end

    context "when there are a lot of participations" do
      before do
        create_list(:participation, Decidim::Paginable::OPTIONS.first + 5, feature: feature)
      end

      it "paginates them" do
        visit_feature

        expect(page).to have_css(".card--participation", count: Decidim::Paginable::OPTIONS.first)

        click_link "Next"

        expect(page).to have_selector(".pagination .current", text: "2")

        expect(page).to have_css(".card--participation", count: 5)
      end
    end

    context "when filtering" do
      context "when official_participations setting is enabled" do
        before do
          feature.update_attributes!(settings: { official_participations_enabled: true })
        end

        it "can be filtered by origin" do
          visit_feature

          within "form.new_filter" do
            expect(page).to have_content(/Origin/i)
          end
        end

        context "with 'official' origin" do
          it "lists the filtered participations" do
            create_list(:participation, 2, :official, feature: feature, scope: scope)
            create(:participation, feature: feature, scope: scope)
            visit_feature

            within ".filters" do
              choose "Official"
            end

            expect(page).to have_css(".card--participation", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end

        context "with 'citizens' origin" do
          it "lists the filtered participations" do
            create_list(:participation, 2, feature: feature, scope: scope)
            create(:participation, :official, feature: feature, scope: scope)
            visit_feature

            within ".filters" do
              choose "Citizens"
            end

            expect(page).to have_css(".card--participation", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end
      end

      context "when official_participations setting is not enabled" do
        before do
          feature.update_attributes!(settings: { official_participations_enabled: false })
        end

        it "cannot be filtered by origin" do
          visit_feature

          within "form.new_filter" do
            expect(page).to have_no_content(/Origin/i)
          end
        end
      end

      context "with scope" do
        let(:scopes_picker) { scopes_picker_find(:filter_scope_id, multiple: true, global_value: "global") }
        let!(:scope2) { create :scope, organization: participatory_process.organization }

        before do
          create_list(:participation, 2, feature: feature, scope: scope)
          create(:participation, feature: feature, scope: scope2)
          create(:participation, feature: feature, scope: nil)
          visit_feature
        end

        it "can be filtered by scope" do
          within "form.new_filter" do
            expect(page).to have_content(/Scopes/i)
          end
        end

        context "when selecting the global scope" do
          it "lists the filtered participations", :slow do
            within ".filters" do
              scope_pick scopes_picker, nil
            end

            expect(page).to have_css(".card--participation", count: 1)
            expect(page).to have_content("1 PROPOSAL")
          end
        end

        context "when selecting one scope" do
          it "lists the filtered participations", :slow do
            within ".filters" do
              scope_pick scopes_picker, scope
            end

            expect(page).to have_css(".card--participation", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end

        context "when selecting the global scope and another scope" do
          it "lists the filtered participations", :slow do
            within ".filters" do
              scope_pick scopes_picker, scope
              scope_pick scopes_picker, nil
            end

            expect(page).to have_css(".card--participation", count: 3)
            expect(page).to have_content("3 PROPOSALS")
          end
        end

        context "when modifying the selected scope" do
          it "lists the filtered participations" do
            within ".filters" do
              scope_pick scopes_picker, scope
              scope_pick scopes_picker, nil
              scope_repick scopes_picker, scope, scope2
            end

            expect(page).to have_css(".card--participation", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end

        context "when unselecting the selected scope" do
          it "lists the filtered participations" do
            within ".filters" do
              scope_pick scopes_picker, scope
              scope_pick scopes_picker, nil
              scope_unpick scopes_picker, scope
            end

            expect(page).to have_css(".card--participation", count: 1)
            expect(page).to have_content("1 PROPOSAL")
          end
        end
      end

      context "when process is related to a scope" do
        let(:participatory_process) { scoped_participatory_process }

        it "cannot be filtered by scope" do
          visit_feature

          within "form.new_filter" do
            expect(page).to have_no_content(/Scopes/i)
          end
        end
      end

      context "when participation_answering feature setting is enabled" do
        before do
          feature.update_attributes!(settings: { participation_answering_enabled: true })
        end

        context "when participation_answering step setting is enabled" do
          before do
            feature.update_attributes!(
              step_settings: {
                feature.participatory_space.active_step.id => {
                  participation_answering_enabled: true
                }
              }
            )
          end

          it "can be filtered by state" do
            visit_feature

            within "form.new_filter" do
              expect(page).to have_content(/State/i)
            end
          end

          it "lists accepted participations" do
            create(:participation, :accepted, feature: feature, scope: scope)
            visit_feature

            within ".filters" do
              choose "Accepted"
            end

            expect(page).to have_css(".card--participation", count: 1)
            expect(page).to have_content("1 PROPOSAL")

            within ".card--participation" do
              expect(page).to have_content("Accepted")
            end
          end

          it "lists the filtered participations" do
            create(:participation, :rejected, feature: feature, scope: scope)
            visit_feature

            within ".filters" do
              choose "Rejected"
            end

            expect(page).to have_css(".card--participation", count: 1)
            expect(page).to have_content("1 PROPOSAL")

            within ".card--participation" do
              expect(page).to have_content("Rejected")
            end
          end
        end

        context "when participation_answering step setting is disabled" do
          before do
            feature.update_attributes!(
              step_settings: {
                feature.participatory_space.active_step.id => {
                  participation_answering_enabled: false
                }
              }
            )
          end

          it "cannot be filtered by state" do
            visit_feature

            within "form.new_filter" do
              expect(page).to have_no_content(/State/i)
            end
          end
        end
      end

      context "when participation_answering feature setting is not enabled" do
        before do
          feature.update_attributes!(settings: { participation_answering_enabled: false })
        end

        it "cannot be filtered by state" do
          visit_feature

          within "form.new_filter" do
            expect(page).to have_no_content(/State/i)
          end
        end
      end

      context "when the user is logged in" do
        before do
          login_as user, scope: :user
        end

        it "can be filtered by category" do
          create_list(:participation, 3, feature: feature)
          create(:participation, feature: feature, category: category)

          visit_feature

          within "form.new_filter" do
            select category.name[I18n.locale.to_s], from: :filter_category_id
          end

          expect(page).to have_css(".card--participation", count: 1)
        end
      end
    end

    context "when ordering by 'most_voted'" do
      let!(:feature) do
        create(:participation_feature,
               :with_votes_enabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      it "lists the participations ordered by votes" do
        most_voted_participation = create(:participation, feature: feature)
        create_list(:participation_vote, 3, participation: most_voted_participation)
        less_voted_participation = create(:participation, feature: feature)

        visit_feature

        within ".order-by" do
          expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Random")
          page.find("a", text: "Random").click
          click_link "Most voted"
        end

        expect(page).to have_selector("#participations .card-grid .column:first-child", text: most_voted_participation.title)
        expect(page).to have_selector("#participations .card-grid .column:last-child", text: less_voted_participation.title)
      end
    end

    context "when ordering by 'recent'" do
      it "lists the participations ordered by created at" do
        older_participation = create(:participation, feature: feature, created_at: 1.month.ago)
        recent_participation = create(:participation, feature: feature)

        visit_feature

        within ".order-by" do
          expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Random")
          page.find("a", text: "Random").click
          click_link "Recent"
        end

        expect(page).to have_selector("#participations .card-grid .column:first-child", text: recent_participation.title)
        expect(page).to have_selector("#participations .card-grid .column:last-child", text: older_participation.title)
      end
    end

    context "when paginating" do
      let!(:collection) { create_list :participation, collection_size, feature: feature }
      let!(:resource_selector) { ".card--participation" }

      it_behaves_like "a paginated resource"
    end
  end
end
