# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    module Admin
      describe ParticipationAnswersController, type: :controller do
        routes { Decidim::Participations::AdminEngine.routes }

        let(:feature) { participation.feature }
        let(:participation) { create(:participation) }
        let(:user) { create(:user, :confirmed, :admin, organization: feature.organization) }

        let(:params) do
          {
            id: participation.id,
            participation_id: participation.id,
            feature_id: feature.id,
            participatory_process_slug: feature.participatory_space.slug,
            state: "rejected"
          }
        end

        before do
          request.env["decidim.current_organization"] = feature.organization
          request.env["decidim.current_feature"] = feature
          sign_in user
        end

        describe "PUT update" do
          context "when the command fails" do
            it "renders the edit template" do
              put :update, params: params

              expect(response).to render_template(:edit)
            end
          end
        end
      end
    end
  end
end
