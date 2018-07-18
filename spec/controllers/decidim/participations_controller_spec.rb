# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe ParticipationsController, type: :controller do
      routes { Decidim::Participations::Engine.routes }

      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: component.participatory_space.slug
        }
      end

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "POST create" do
        context "when creation is not enabled" do
          let(:component) { create(:participation_component) }

          it "raises an error" do
            expect(CreateParticipation).not_to receive(:call)

            post :create, params: params

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(302)
          end
        end

        context "when creation is enabled" do
          let(:component) { create(:participation_component, :with_creation_enabled) }

          it "creates a participation" do
            expect(CreateParticipation).to receive(:call)

            post :create, params: params
          end
        end
      end
    end
  end
end
