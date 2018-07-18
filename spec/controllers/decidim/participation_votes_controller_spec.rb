# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe ParticipationVotesController, type: :controller do
      routes { Decidim::Participations::Engine.routes }

      let(:participation) { create(:participation, component: component) }
      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:params) do
        {
          participation_id: participation.id,
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
        context "with votes enabled" do
          let(:component) do
            create(:participation_component, :with_votes_enabled)
          end

          it "allows voting" do
            expect do
              post :create, format: :js, params: params
            end.to change { ParticipationVote.count }.by(1)

            expect(ParticipationVote.last.author).to eq(user)
            expect(ParticipationVote.last.participation).to eq(participation)
          end
        end

        context "with votes disabled" do
          let(:component) do
            create(:participation_component)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change { ParticipationVote.count }

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(302)
          end
        end

        context "with votes enabled but votes blocked" do
          let(:component) do
            create(:participation_component, :with_votes_blocked)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change { ParticipationVote.count }

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(302)
          end
        end
      end

      describe "destroy" do
        before do
          create(:participation_vote, participation: participation, author: user)
        end

        context "with vote limit enabled" do
          let(:component) do
            create(:participation_component, :with_votes_enabled, :with_vote_limit)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change { ParticipationVote.count }.by(-1)

            expect(ParticipationVote.count).to eq(0)
          end
        end

        context "with vote limit disabled" do
          let(:component) do
            create(:participation_component, :with_votes_enabled)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change { ParticipationVote.count }.by(-1)

            expect(ParticipationVote.count).to eq(0)
          end
        end
      end
    end
  end
end
