# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe ParticipationSearch do
      let(:component) { create(:component, manifest_name: "participations") }
      let(:scope1) { create :scope, organization: component.organization }
      let(:scope2) { create :scope, organization: component.organization }
      let(:subscope1) { create :scope, organization: component.organization, parent: scope1 }
      let(:participatory_process) { component.participatory_space }
      let(:user) { create(:user, organization: component.organization) }
      let!(:participation) { create(:participation, component: component, scope: scope1) }

      describe "results" do
        subject do
          described_class.new(
            component: component,
            activity: activity,
            search_text: search_text,
            state: state,
            origin: origin,
            related_to: related_to,
            scope_id: scope_id,
            current_user: user
          ).results
        end

        let(:activity) { [] }
        let(:search_text) { nil }
        let(:origin) { nil }
        let(:related_to) { nil }
        let(:state) { nil }
        let(:scope_id) { nil }

        it "only includes participations from the given component" do
          other_participation = create(:participation)

          expect(subject).to include(participation)
          expect(subject).not_to include(other_participation)
        end

        describe "search_text filter" do
          let(:search_text) { "dog" }

          it "returns the participations containing the search in the title or the body" do
            create_list(:participation, 3, component: component)
            create(:participation, title: "A dog", component: component)
            create(:participation, body: "There is a dog in the office", component: component)

            expect(subject.size).to eq(2)
          end
        end

        describe "activity filter" do
          let(:activity) { ["voted"] }

          it "returns the participations voted by the user" do
            create_list(:participation, 3, component: component)
            create(:participation_vote, participation: Participation.first, author: user)

            expect(subject.size).to eq(1)
          end
        end

        describe "origin filter" do
          context "when filtering official participations" do
            let(:origin) { "official" }

            it "returns only official participations" do
              official_participations = create_list(:participation, 3, :official, component: component)
              create_list(:participation, 3, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(official_participations)
            end
          end

          context "when filtering citizen participations" do
            let(:origin) { "citizens" }

            it "returns only citizen participations" do
              create_list(:participation, 3, :official, component: component)
              citizen_participations = create_list(:participation, 2, component: component)
              citizen_participations << participation

              expect(subject.size).to eq(3)
              expect(subject).to match_array(citizen_participations)
            end
          end
        end

        describe "state filter" do
          context "when filtering accpeted participations" do
            let(:state) { "accepted" }

            it "returns only accepted participations" do
              accepted_participations = create_list(:participation, 3, :accepted, component: component)
              create_list(:participation, 3, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(accepted_participations)
            end
          end

          context "when filtering rejected participations" do
            let(:state) { "rejected" }

            it "returns only rejected participations" do
              create_list(:participation, 3, component: component)
              rejected_participations = create_list(:participation, 3, :rejected, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(rejected_participations)
            end
          end
        end

        describe "scope_id filter" do
          let!(:participation2) { create(:participation, component: component, scope: scope2) }
          let!(:participation3) { create(:participation, component: component, scope: subscope1) }

          context "when a parent scope id is being sent" do
            let(:scope_id) { scope1.id }

            it "filters participations by scope" do
              expect(subject).to match_array [participation, participation3]
            end
          end

          context "when a subscope id is being sent" do
            let(:scope_id) { subscope1.id }

            it "filters participations by scope" do
              expect(subject).to eq [participation3]
            end
          end

          context "when multiple ids are sent" do
            let(:scope_id) { [scope2.id, scope1.id] }

            it "filters participations by scope" do
              expect(subject).to match_array [participation, participation2, participation3]
            end
          end

          context "when `global` is being sent" do
            let!(:resource_without_scope) { create(:participation, component: component, scope: nil) }
            let(:scope_id) { ["global"] }

            it "returns participations without a scope" do
              expect(subject).to eq [resource_without_scope]
            end
          end

          context "when `global` and some ids is being sent" do
            let!(:resource_without_scope) { create(:participation, component: component, scope: nil) }
            let(:scope_id) { ["global", scope2.id, scope1.id] }

            it "returns participations without a scope and with selected scopes" do
              expect(subject).to match_array [resource_without_scope, participation, participation2, participation3]
            end
          end
        end

        describe "related_to filter" do
          context "when filtering by related to meetings" do
            let(:related_to) { "Decidim::Meetings::Meeting".underscore }
            let(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
            let(:meeting) { create :meeting, component: meetings_component }

            it "returns only participations related to meetings" do
              related_participation = create(:participation, :accepted, component: component)
              related_participation2 = create(:participation, :accepted, component: component)
              create_list(:participation, 3, component: component)
              meeting.link_resources([related_participation], "participations_from_meeting")
              related_participation2.link_resources([meeting], "participations_from_meeting")

              expect(subject).to match_array([related_participation, related_participation2])
            end
          end

          context "when filtering by related to resources" do
            let(:related_to) { "Decidim::DummyResources::DummyResource".underscore }
            let(:dummy_component) { create(:component, manifest_name: "dummy", participatory_space: participatory_process) }
            let(:dummy_resource) { create :dummy_resource, component: dummy_component }

            it "returns only participations related to results" do
              related_participation = create(:participation, :accepted, component: component)
              related_participation2 = create(:participation, :accepted, component: component)
              create_list(:participation, 3, component: component)
              dummy_resource.link_resources([related_participation], "included_participations")
              related_participation2.link_resources([dummy_resource], "included_participations")

              expect(subject).to match_array([related_participation, related_participation2])
            end
          end
        end
      end
    end
  end
end
