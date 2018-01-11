# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    describe ApplicationHelper do
      describe "humanize_participation_state" do
        subject { helper.humanize_participation_state(state) }

        let(:helper) do
          Class.new.tap do |v|
            v.extend(Decidim::Participations::ApplicationHelper)
          end
        end

        context "when it is accepted" do
          let(:state) { "accepted" }

          it { is_expected.to eq("Accepted") }
        end

        context "when it is rejected" do
          let(:state) { "rejected" }

          it { is_expected.to eq("Rejected") }
        end

        context "when it is nil" do
          let(:state) { nil }

          it { is_expected.to eq("Not answered") }
        end
      end
    end
  end
end
