# frozen_string_literal: true

shared_examples "create a participation" do |with_author|
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

  if with_author
    let(:author) { create(:user, organization: organization) }

    let(:user_group) do
      create(:user_group, :verified, organization: organization, users: [author])
    end
  end

  let(:has_address) { false }
  let(:address) { nil }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:attachment_params) { nil }

  describe "call" do
    let(:form_params) do
      {
        title: "A reasonable participation title",
        body: "A reasonable participation body",
        address: address,
        has_address: has_address,
        attachment: attachment_params,
        user_group_id: (with_author ? user_group.try(:id) : nil)
      }
    end

    let(:command) do
      if with_author
        described_class.new(form, author)
      else
        described_class.new(form)
      end
    end

    describe "when the form is not valid" do
      before do
        expect(form).to receive(:invalid?).and_return(true)
      end

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "doesn't create a participation" do
        expect do
          command.call
        end.not_to change { Decidim::Participations::Participation.count }
      end
    end

    describe "when the form is valid" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "creates a new participation" do
        expect do
          command.call
        end.to change { Decidim::Participations::Participation.count }.by(1)
      end

      if with_author
        context "with an author" do
          let(:user_group) { nil }

          it "sets the author" do
            command.call
            participation = Decidim::Participations::Participation.last

            expect(participation.author).to eq(author)
            expect(participation.user_group).to eq(nil)
          end

          context "with a participation limit" do
            let(:feature) do
              create(:participation_feature, settings: { "participation_limit" => 2 })
            end

            it "checks the author doesn't exceed the amount of participations" do
              expect { command.call }.to broadcast(:ok)
              expect { command.call }.to broadcast(:ok)
              expect { command.call }.to broadcast(:invalid)
            end
          end
        end

        context "with a user group" do
          it "sets the user group" do
            command.call
            participation = Decidim::Participations::Participation.last

            expect(participation.author).to eq(author)
            expect(participation.user_group).to eq(user_group)
          end

          context "with a participation limit" do
            let(:feature) do
              create(:participation_feature, settings: { "participation_limit" => 2 })
            end

            before do
              create_list(:participation, 2, feature: feature, author: author)
            end

            it "checks the user group doesn't exceed the amount of participations independently of the author" do
              expect { command.call }.to broadcast(:ok)
              expect { command.call }.to broadcast(:ok)
              expect { command.call }.to broadcast(:invalid)
            end
          end
        end
      end

      context "when geocoding is enabled" do
        let(:feature) { create(:participation_feature, :with_geocoding_enabled) }

        context "when the has address checkbox is checked" do
          let(:has_address) { true }

          context "when the address is present" do
            let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }

            before do
              Geocoder::Lookup::Test.add_stub(
                address,
                [{ "latitude" => latitude, "longitude" => longitude }]
              )
            end

            it "sets the latitude and longitude" do
              command.call
              participation = Decidim::Participations::Participation.last

              expect(participation.latitude).to eq(latitude)
              expect(participation.longitude).to eq(longitude)
            end
          end
        end
      end

      context "when attachments are allowed", processing_uploads_for: Decidim::AttachmentUploader do
        let(:feature) { create(:participation_feature, :with_attachments_allowed) }
        let(:attachment_params) do
          {
            title: "My attachment",
            file: Decidim::Dev.test_file("city.jpeg", "image/jpeg")
          }
        end

        it "creates an atachment for the participation" do
          expect do
            command.call
          end.to change { Decidim::Attachment.count }.by(1)
          last_participation = Decidim::Participations::Participation.last
          last_attachment = Decidim::Attachment.last
          expect(last_attachment.attached_to).to eq(last_participation)
        end

        context "when attachment is left blank" do
          let(:attachment_params) do
            {
              title: ""
            }
          end

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end
        end
      end
    end
  end
end
