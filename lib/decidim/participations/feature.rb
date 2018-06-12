# frozen_string_literal: true

require "decidim/components/namer"

Decidim.register_component(:participations) do |component|
  component.engine = Decidim::Participations::Engine
  component.admin_engine = Decidim::Participations::AdminEngine
  component.icon = "decidim/participations/icon.svg"

  component.on(:before_destroy) do |instance|
    if Decidim::Participations::Participation.where(component: instance).any?
      raise "Can't destroy this component when there are participations"
    end
  end

  component.actions = %w(vote create)

  component.settings(:global) do |settings|
    settings.attribute :vote_limit, type: :integer, default: 0
    settings.attribute :participation_limit, type: :integer, default: 0
    settings.attribute :participation_edit_before_minutes, type: :integer, default: 5
    settings.attribute :maximum_votes_per_participation, type: :integer, default: 0
    settings.attribute :participation_answering_enabled, type: :boolean, default: true
    settings.attribute :official_participations_enabled, type: :boolean, default: true
    settings.attribute :comments_enabled, type: :boolean, default: true
    settings.attribute :comments_upstream_moderation_enabled, type: :boolean, default: false
    settings.attribute :geocoding_enabled, type: :boolean, default: false
    settings.attribute :attachments_allowed, type: :boolean, default: false
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :new_participation_help_text, type: :text, translated: true, editor: true
  end

  component.settings(:step) do |settings|
    settings.attribute :votes_enabled, type: :boolean
    settings.attribute :votes_blocked, type: :boolean
    settings.attribute :votes_hidden, type: :boolean, default: false
    settings.attribute :comments_blocked, type: :boolean, default: false
    settings.attribute :creation_enabled, type: :boolean
    settings.attribute :participation_answering_enabled, type: :boolean, default: true
    settings.attribute :announcement, type: :text, translated: true, editor: true
  end

  component.register_resource do |resource|
    resource.model_class_name = "Decidim::Participations::Participation"
    resource.template = "decidim/participations/participations/linked_participations"
  end

  component.register_stat :participations_count, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Participations::FilteredParticipations.for(components, start_at, end_at).count
  end

  component.register_stat :participations_accepted, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Participations::FilteredParticipations.for(components, start_at, end_at).accepted.count
  end

  component.register_stat :votes_count, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    participations = Decidim::Participations::FilteredParticipations.for(components, start_at, end_at).not_hidden
    Decidim::Participations::ParticipationVote.where(participation: participations).count
  end

  component.register_stat :comments_count, tag: :comments do |components, start_at, end_at|
    participations = Decidim::Participations::FilteredParticipations.for(components, start_at, end_at).not_hidden
    Decidim::Comments::Comment.where(root_commentable: participations).count
  end

  component.exports :participations do |exports|
    exports.collection do |component_instance|
      Decidim::Participations::Participation
        .where(component: component_instance)
        .includes(:category, component: { participatory_space: :organization })
    end

    exports.serializer Decidim::Participations::ParticipationSerializer
  end

  component.exports :comments do |exports|
    exports.collection do |component_instance|
      Decidim::Comments::Export.comments_for_resource(
        Decidim::Participations::Participation, component_instance
      )
    end

    exports.serializer Decidim::Comments::CommentSerializer
  end

  component.seeds do |participatory_space|
    step_settings = if participatory_space.allows_steps?
                      { participatory_space.active_step.id => { votes_enabled: true, votes_blocked: false, creation_enabled: true } }
                    else
                      {}
                    end

    component = Decidim::Component.create!(
      name: Decidim::Components::Namer.new(participatory_space.organization.available_locales, :participations).i18n_name,
      manifest_name: :participations,
      published_at: Time.current,
      participatory_space: participatory_space,
      settings: {
        vote_limit: 0
      },
      step_settings: step_settings
    )

    if participatory_space.scope
      scopes = participatory_space.scope.descendants
      global = participatory_space.scope
    else
      scopes = participatory_space.organization.scopes
      global = nil
    end

    5.times do |n|
      author = Decidim::User.where(organization: component.organization).all.sample
      user_group = [true, false].sample ? author.user_groups.verified.sample : nil
      state, answer = if n > 3
                        ["accepted", Decidim::Faker::Localized.sentence(10)]
                      elsif n > 2
                        ["rejected", nil]
                      elsif n > 1
                        ["evaluating", nil]
                      else
                        [nil, nil]
                      end
      body = Faker::Lorem.paragraphs(2).join("\n")
      participation = Decidim::Participations::Participation.create!(
        component: component,
        category: participatory_space.categories.sample,
        scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
        title: "Question n°#{n}",
        original_body: body,
        body: body,
        author: author,
        user_group: user_group,
        state: state,
        answer: answer,
        answered_at: Time.current,

        participation_type: %w(question opinion contribution)[Faker::Number.between(0, 2)]
      )

      (n % 3).times do |m|
        email = "vote-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-#{m}@example.org"
        name = "#{Faker::Name.name} #{participatory_space.id} #{n} #{m}"

        author = Decidim::User.find_or_initialize_by(email: email)
        author.update!(
          password: "password1234",
          password_confirmation: "password1234",
          name: name,
          nickname: Faker::Twitter.unique.screen_name,
          organization: component.organization,
          tos_agreement: "1",
          confirmed_at: Time.current
        )

        Decidim::Participations::ParticipationVote.create!(participation: participation, author: author) unless participation.answered? && participation.rejected?
      end

      Decidim::Comments::Seed.comments_for(participation)
    end
  end
end
