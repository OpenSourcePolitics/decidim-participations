# frozen_string_literal: true

require "spec_helper"

describe Decidim::Participations::Abilities::ParticipatoryProcessAdminAbility do
  subject { described_class.new(user, context) }

  let(:user) { build(:user) }
  let(:user_process) { create :participatory_process, organization: user.organization }
  let!(:user_process_role) { create :participatory_process_user_role, user: user, participatory_process: user_process, role: :admin }
  let(:feature) { create :participation_feature, participatory_space: user_process }
  let(:participations) { create_list :participation, 3, feature: feature }
  let(:other_participations) { create_list :participation, 3 }
  let(:context) { { current_participatory_process: user_process } }

  context "when the user is an admin" do
    let(:user) { build(:user, :admin) }

    it "doesn't have any permission" do
      expect(subject.permissions[:can]).to be_empty
      expect(subject.permissions[:cannot]).to be_empty
    end
  end

  it { is_expected.to be_able_to(:manage, Decidim::Participations::Participation) }

  context "when creation is disabled" do
    let(:context) do
      {
        current_participatory_process: user_process,
        current_settings: double(creation_enabled?: false),
        feature_settings: double(official_participations_enabled: true)
      }
    end

    it { is_expected.not_to be_able_to(:create, Decidim::Participations::Participation) }
  end

  context "when official participations are disabled" do
    let(:context) do
      {
        current_participatory_process: user_process,
        current_settings: double(creation_enabled?: true),
        feature_settings: double(official_participations_enabled: false)
      }
    end

    it { is_expected.not_to be_able_to(:create, Decidim::Participations::Participation) }
  end

  context "when participation_answering is disabled in step level" do
    let(:context) do
      {
        current_participatory_process: user_process,
        current_settings: double(participation_answering_enabled: false)
      }
    end

    it { is_expected.not_to be_able_to(:update, Decidim::Participations::Participation) }
  end

  context "when participation_answering is disabled in feature level" do
    let(:context) do
      {
        current_participatory_process: user_process,
        feature_settings: double(participation_answering_enabled: false)
      }
    end

    it { is_expected.not_to be_able_to(:update, Decidim::Participations::Participation) }
  end
end
