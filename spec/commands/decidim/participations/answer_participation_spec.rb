# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Participations
    module Admin
      describe AnswerParticipation do
        describe "call" do
          let(:participation) { create(:participation) }
          let(:form) { ParticipationAnswerForm.from_params(form_params) }
          let(:form_params) do
            {
              state: "rejected", answer: { en: "Foo" }
            }
          end

          let(:command) { described_class.new(form, participation) }

          describe "when the form is not valid" do
            before do
              expect(form).to receive(:invalid?).and_return(true)
            end

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't update the participation" do
              expect(participation).not_to receive(:update_attributes!)
              command.call
            end
          end

          describe "when the form is valid" do
            before do
              expect(form).to receive(:invalid?).and_return(false)
            end

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "updates the participation" do
              command.call

              expect(participation.reload).to be_answered
            end
          end
        end
      end
    end
  end
end
