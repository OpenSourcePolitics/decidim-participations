# frozen_string_literal: true

require "spec_helper"

describe Decidim::Participations::Abilities::CurrentUserAbility do
  subject { described_class.new(user, context) }

  let(:user) { build(:user) }
  let(:participation_component) { create :participation_component }
  let(:extra_context) do
    {
      current_settings: current_settings,
      component_settings: component_settings
    }
  end
  let(:context) do
    {
      current_component: participation_component
    }.merge(extra_context)
  end
  let(:settings) do
    {
      creation_enabled?: false,
      votes_enabled?: false,
      votes_blocked?: true
    }
  end
  let(:extra_settings) { {} }
  let(:current_settings) { double(settings.merge(extra_settings)) }
  let(:component_settings) { double(participation_edit_before_minutes: 5) }

  it { is_expected.to be_able_to(:report, Decidim::Participations::Participation) }

  describe "voting" do
    context "when voting is disabled" do
      let(:participation) { build :participation, component: participation_component }
      let(:extra_settings) do
        {
          votes_enabled?: false,
          votes_blocked?: true
        }
      end

      it { is_expected.not_to be_able_to(:unvote, participation) }
    end

    context "when user is authorized" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: false
        }
      end

      it { is_expected.to be_able_to(:unvote, Decidim::Participations::Participation) }
    end
  end

  describe "unvoting" do
    context "when voting is disabled" do
      let(:participation) { build :participation, component: participation_component }
      let(:extra_settings) do
        {
          votes_enabled?: false,
          votes_blocked?: true
        }
      end

      it { is_expected.not_to be_able_to(:unvote, participation) }
    end

    context "when user is authorized" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: false
        }
      end

      it { is_expected.to be_able_to(:unvote, Decidim::Participations::Participation) }
    end
  end

  describe "participation creation" do
    context "when creation is disabled" do
      let(:extra_settings) do
        {
          creation_enabled?: false
        }
      end

      it { is_expected.not_to be_able_to(:create, Decidim::Participations::Participation) }
    end

    context "when user is authorized" do
      let(:extra_settings) do
        {
          creation_enabled?: true
        }
      end

      it { is_expected.to be_able_to(:create, Decidim::Participations::Participation) }
    end
  end

  describe "participation edition" do
    let(:participation) { build :participation, author: user, created_at: Time.current, component: participation_component }

    context "when participation is editable" do
      before do
        allow(participation).to receive(:editable_by?).and_return(true)
      end

      it { is_expected.to be_able_to(:edit, participation) }
    end

    context "when participation is not editable" do
      before do
        allow(participation).to receive(:editable_by?).and_return(false)
      end

      it { is_expected.not_to be_able_to(:edit, participation) }
    end
  end
end
