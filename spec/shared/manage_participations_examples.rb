# frozen_string_literal: true

shared_examples "manage participations" do
  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: participatory_process_scope) }
  let(:participatory_process_scope) { nil }

  before do
    Geocoder::Lookup::Test.add_stub(
      address,
      [{ "latitude" => latitude, "longitude" => longitude }]
    )
  end

  context "when previewing participations" do
    it "allows the user to preview the participation" do
      within find("tr", text: participation.title) do
        klass = "action-icon--preview"
        href = resource_locator(participation).path
        target = "blank"

        expect(page).to have_selector(
          :xpath,
          "//a[contains(@class,'#{klass}')][@href='#{href}'][@target='#{target}']"
        )
      end
    end
  end

  describe "creation" do
    context "when official_participations setting is enabled" do
      before do
        current_feature.update_attributes!(settings: { official_participations_enabled: true })
      end

      context "when creation is enabled" do
        before do
          current_feature.update_attributes!(
            step_settings: {
              current_feature.participatory_space.active_step.id => {
                creation_enabled: true
              }
            }
          )

          visit_feature_admin
        end

        context "when process is not related to any scope" do
          it "can be related to a scope" do
            click_link "New"

            within "form" do
              expect(page).to have_content(/Scope/i)
            end
          end

          it "creates a new participation", :slow do
            click_link "New"

            within ".new_participation" do
              fill_in :participation_title, with: "Make decidim great again"
              fill_in :participation_body, with: "Decidim is great but it can be better"
              select translated(category.name), from: :participation_category_id
              scope_pick scopes_picker_find(:participation_scope_id), scope
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              participation = Decidim::Participations::Participation.last

              expect(page).to have_content("Make decidim great again")
              expect(participation.body).to eq("Decidim is great but it can be better")
              expect(participation.category).to eq(category)
              expect(participation.scope).to eq(scope)
            end
          end
        end

        context "when process is related to a scope" do
          let(:participatory_process_scope) { scope }

          it "cannot be related to a scope, because it has no children" do
            click_link "New"

            within "form" do
              expect(page).to have_no_content(/Scope/i)
            end
          end

          it "creates a new participation related to the process scope" do
            click_link "New"

            within ".new_participation" do
              fill_in :participation_title, with: "Make decidim great again"
              fill_in :participation_body, with: "Decidim is great but it can be better"
              select category.name["en"], from: :participation_category_id
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              participation = Decidim::Participations::Participation.last

              expect(page).to have_content("Make decidim great again")
              expect(participation.body).to eq("Decidim is great but it can be better")
              expect(participation.category).to eq(category)
              expect(participation.scope).to eq(scope)
            end
          end

          context "when the process scope has a child scope" do
            let!(:child_scope) { create :scope, parent: scope }

            it "can be related to a scope" do
              click_link "New"

              within "form" do
                expect(page).to have_content(/Scope/i)
              end
            end

            it "creates a new participation related to a process scope child" do
              click_link "New"

              within ".new_participation" do
                fill_in :participation_title, with: "Make decidim great again"
                fill_in :participation_body, with: "Decidim is great but it can be better"
                select category.name["en"], from: :participation_category_id
                scope_repick scopes_picker_find(:participation_scope_id), scope, child_scope
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                participation = Decidim::Participations::Participation.last

                expect(page).to have_content("Make decidim great again")
                expect(participation.body).to eq("Decidim is great but it can be better")
                expect(participation.category).to eq(category)
                expect(participation.scope).to eq(child_scope)
              end
            end
          end

          context "when geocoding is enabled" do
            before do
              current_feature.update_attributes!(settings: { geocoding_enabled: true })
            end

            it "creates a new participation related to the process scope" do
              click_link "New"

              within ".new_participation" do
                fill_in :participation_title, with: "Make decidim great again"
                fill_in :participation_body, with: "Decidim is great but it can be better"
                fill_in :participation_address, with: address
                select category.name["en"], from: :participation_category_id
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                participation = Decidim::Participations::Participation.last

                expect(page).to have_content("Make decidim great again")
                expect(participation.body).to eq("Decidim is great but it can be better")
                expect(participation.category).to eq(category)
                expect(participation.scope).to eq(scope)
              end
            end
          end
        end

        context "when attachments are allowed", processing_uploads_for: Decidim::AttachmentUploader do
          before do
            current_feature.update_attributes!(settings: { attachments_allowed: true })
          end

          it "creates a new participation with attachments" do
            click_link "New"

            within ".new_participation" do
              fill_in :participation_title, with: "Participation with attachments"
              fill_in :participation_body, with: "This is my participation and I want to upload attachments."
              fill_in :participation_attachment_title, with: "My attachment"
              attach_file :participation_attachment_file, Decidim::Dev.asset("city.jpeg")
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            visit resource_locator(Decidim::Participations::Participation.last).path
            expect(page).to have_selector("img[src*=\"city.jpeg\"]", count: 1)
          end
        end
      end

      context "when creation is not enabled" do
        before do
          current_feature.update_attributes!(
            step_settings: {
              current_feature.participatory_space.active_step.id => {
                creation_enabled: false
              }
            }
          )
        end

        it "cannot create a new participation from the main site" do
          visit_feature
          expect(page).to have_no_button("New Participation")
        end

        it "cannot create a new participation from the admin site" do
          visit_feature_admin
          expect(page).to have_no_link(/New/)
        end
      end
    end

    context "when official_participations setting is disabled" do
      before do
        current_feature.update_attributes!(settings: { official_participations_enabled: false })
      end

      it "cannot create a new participation from the main site" do
        visit_feature
        expect(page).to have_no_button("New Participation")
      end

      it "cannot create a new participation from the admin site" do
        visit_feature_admin
        expect(page).to have_no_link(/New/)
      end
    end
  end

  context "when the participation_answering feature setting is enabled" do
    before do
      current_feature.update_attributes!(settings: { participation_answering_enabled: true })
    end

    context "when the participation_answering step setting is enabled" do
      before do
        current_feature.update_attributes!(
          step_settings: {
            current_feature.participatory_space.active_step.id => {
              participation_answering_enabled: true
            }
          }
        )
      end

      it "can reject a participation" do
        go_to_edit_answer(participation)

        within ".edit_participation_answer" do
          fill_in_i18n_editor(
            :participation_answer_answer,
            "#participation_answer-answer-tabs",
            en: "The participation doesn't make any sense",
            es: "La propuesta no tiene sentido",
            ca: "La proposta no te sentit"
          )
          choose "Rejected"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Participation successfully answered")

        within find("tr", text: participation.title) do
          expect(page).to have_content("Rejected")
        end
      end

      it "can accept a participation" do
        go_to_edit_answer(participation)

        within ".edit_participation_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Participation successfully answered")

        within find("tr", text: participation.title) do
          expect(page).to have_content("Accepted")
        end
      end

      it "can mark a participation as evaluating" do
        go_to_edit_answer(participation)

        within ".edit_participation_answer" do
          choose "Evaluating"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Participation successfully answered")

        within find("tr", text: participation.title) do
          expect(page).to have_content("Evaluating")
        end
      end

      it "can edit a participation answer" do
        participation.update_attributes!(
          state: "rejected",
          answer: {
            "en" => "I don't like it"
          },
          answered_at: Time.current
        )

        visit_feature_admin

        within find("tr", text: participation.title) do
          expect(page).to have_content("Rejected")
        end

        go_to_edit_answer(participation)

        within ".edit_participation_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Participation successfully answered")

        within find("tr", text: participation.title) do
          expect(page).to have_content("Accepted")
        end
      end
    end

    context "when the participation_answering step setting is disabled" do
      before do
        current_feature.update_attributes!(
          step_settings: {
            current_feature.participatory_space.active_step.id => {
              participation_answering_enabled: false
            }
          }
        )
      end

      it "cannot answer a participation" do
        visit current_path

        within find("tr", text: participation.title) do
          expect(page).to have_no_link("Answer")
        end
      end
    end
  end

  context "when the participation_answering feature setting is disabled" do
    before do
      current_feature.update_attributes!(settings: { participation_answering_enabled: false })
    end

    it "cannot answer a participation" do
      visit current_path

      within find("tr", text: participation.title) do
        expect(page).to have_no_link("Answer")
      end
    end
  end

  context "when the votes_enabled feature setting is disabled" do
    before do
      current_feature.update_attributes!(
        step_settings: {
          feature.participatory_space.active_step.id => {
            votes_enabled: false
          }
        }
      )
    end

    it "doesn't show the votes column" do
      visit current_path

      within "thead" do
        expect(page).not_to have_content("VOTES")
      end
    end
  end

  context "when the votes_enabled feature setting is enabled" do
    before do
      current_feature.update_attributes!(
        step_settings: {
          feature.participatory_space.active_step.id => {
            votes_enabled: true
          }
        }
      )
    end

    it "shows the votes column" do
      visit current_path

      within "thead" do
        expect(page).to have_content("VOTES")
      end
    end
  end

  def go_to_edit_answer(participation)
    within find("tr", text: participation.title) do
      click_link "Answer"
    end

    expect(page).to have_selector(".edit_participation_answer")
  end
end
