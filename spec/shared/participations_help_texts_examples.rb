# frozen_string_literal: true

shared_examples "manage participations help texts" do
  before do
    current_component.update_attributes!(
      step_settings: {
        current_component.participatory_space.active_step.id => {
          creation_enabled: true
        }
      }
    )
  end

  it "customize a help text for the new participation page" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_new_participation_help_text,
      "#global-settings-new_participation_help_text-tabs",
      en: "Create a participation following our guidelines.",
      es: "Crea una propuesta siguiendo nuestra guía de estilo.",
      ca: "Crea una proposta seguint la nostra guia d'estil."
    )

    click_button "Update"

    visit new_participation_path(current_component)

    within ".callout.secondary" do
      expect(page).to have_content("Create a participation following our guidelines.")
    end
  end

  private

  def new_participation_path(component)
    Decidim::EngineRouter.main_proxy(component).new_participation_path(current_component.id)
  end
end
