# frozen_string_literal: true

shared_examples "manage participations help texts" do
  before do
    current_feature.update_attributes!(
      step_settings: {
        current_feature.participatory_space.active_step.id => {
          creation_enabled: true
        }
      }
    )
  end

  it "customize a help text for the new participation page" do
    visit edit_feature_path(current_feature)

    fill_in_i18n_editor(
      :feature_settings_new_participation_help_text,
      "#global-settings-new_participation_help_text-tabs",
      en: "Create a participation following our guidelines.",
      es: "Crea una propuesta siguiendo nuestra guía de estilo.",
      ca: "Crea una proposta seguint la nostra guia d'estil."
    )

    click_button "Update"

    visit new_participation_path(current_feature)

    within ".callout.secondary" do
      expect(page).to have_content("Create a participation following our guidelines.")
    end
  end

  private

  def new_participation_path(feature)
    Decidim::EngineRouter.main_proxy(feature).new_participation_path(current_feature.id)
  end
end
