# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe CreateParticipation do
      let(:form_klass) { ParticipationForm }

      it_behaves_like "create a participation", true

      describe "events" do
        subject do
          described_class.new(form, author)
        end

        let(:feature) { create(:participation_feature) }
        let(:organization) { feature.organization }
        let(:form) do
          form_klass.from_params(
            form_params
          ).with_context(
            current_organization: organization,
            current_feature: feature
          )
        end
        let(:form_params) do
          {
            title: "A reasonable participation title",
            body: "A reasonable participation body",
            address: nil,
            has_address: false,
            attachment: nil,
            user_group_id: nil
          }
        end
        let(:author) { create(:user, organization: organization) }
        let(:follower) { create(:user, organization: organization) }
        let!(:follow) { create :follow, followable: author, user: follower }

        it "notifies the change" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.participations.participation_created",
              event_class: Decidim::Participations::CreateParticipationEvent,
              resource: kind_of(Decidim::Participations::Participation),
              recipient_ids: [follower.id]
            )

          subject.call
        end
      end
    end
  end
end
