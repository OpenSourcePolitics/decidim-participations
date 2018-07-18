# frozen_string_literal: true

require "spec_helper"

describe Decidim::Participations::Abilities::AdminAbility do
  subject { described_class.new(user, context) }

  let(:user) { build(:user, :admin) }
  let(:context) { {} }

  context "when the user is not an admin" do
    let(:user) { build(:user) }

    it "doesn't have any permission" do
      expect(subject.permissions[:can]).to be_empty
      expect(subject.permissions[:cannot]).to be_empty
    end
  end

  it { is_expected.to be_able_to(:manage, Decidim::Participations::Participation) }

  context "when creation is disabled" do
    let(:context) do
      {
        current_settings: double(creation_enabled?: false),
        component_settings: double(official_participations_enabled: true)
      }
    end

    it { is_expected.not_to be_able_to(:create, Decidim::Participations::Participation) }
  end

  context "when official participations are disabled" do
    let(:context) do
      {
        current_settings: double(creation_enabled?: true),
        component_settings: double(official_participations_enabled: false)
      }
    end

    it { is_expected.not_to be_able_to(:create, Decidim::Participations::Participation) }
  end

  context "when participation_answering is disabled in step level" do
    let(:context) do
      {
        current_settings: double(participation_answering_enabled: false)
      }
    end

    it { is_expected.not_to be_able_to(:update, Decidim::Participations::Participation) }
  end

  context "when participation_answering is disabled in component level" do
    let(:context) do
      {
        component_settings: double(participation_answering_enabled: false)
      }
    end

    it { is_expected.not_to be_able_to(:update, Decidim::Participations::Participation) }
  end
end
