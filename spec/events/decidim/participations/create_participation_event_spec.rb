# frozen_string_literal: true

require "spec_helper"

describe Decidim::Participations::CreateParticipationEvent do
  subject do
    described_class.new(resource: participation, event_name: event_name, user: user, extra: {})
  end

  let(:organization) { participation.organization }
  let(:participation) { create :participation }
  let(:participation_author) { participation.author }
  let(:event_name) { "decidim.events.participations.participation_created" }
  let(:user) { create :user, organization: organization }
  let(:resource_path) { resource_locator(participation).path }

  describe "types" do
    subject { described_class }

    it "supports notifications" do
      expect(subject.types).to include :notification
    end

    it "supports emails" do
      expect(subject.types).to include :email
    end
  end

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("New participation by @#{participation_author.nickname}")
    end
  end

  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq("Hi,\n#{participation_author.name} @#{participation_author.nickname}, who you are following, has created a new participation, check it out and contribute:")
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("You have received this notification because you are following @#{participation_author.nickname}. You can stop receiving notifications following the previous link.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include("The <a href=\"#{resource_path}\">#{participation.title}</a> participation was created by ")

      expect(subject.notification_title)
        .to include("<a href=\"/profiles/#{participation_author.nickname}\">#{participation_author.name} @#{participation_author.nickname}</a>.")
    end
  end
end
