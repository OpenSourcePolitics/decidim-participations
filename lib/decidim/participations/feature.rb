# frozen_string_literal: true

require "decidim/features/namer"

Decidim.register_feature(:participations) do |feature|
  feature.engine = Decidim::Participations::Engine
  feature.admin_engine = Decidim::Participations::AdminEngine
  feature.icon = "decidim/participations/icon.svg"

  feature.on(:before_destroy) do |instance|
    if Decidim::Participations::Participation.where(feature: instance).any?
      raise "Can't destroy this feature when there are participations"
    end
  end

  feature.actions = %w(vote create)

  feature.settings(:global) do |settings|
    settings.attribute :vote_limit, type: :integer, default: 0
    settings.attribute :participation_limit, type: :integer, default: 0
    settings.attribute :participation_edit_before_minutes, type: :integer, default: 5
    settings.attribute :maximum_votes_per_participation, type: :integer, default: 0
    settings.attribute :participation_answering_enabled, type: :boolean, default: true
    settings.attribute :official_participations_enabled, type: :boolean, default: true
    settings.attribute :comments_enabled, type: :boolean, default: true
    settings.attribute :upstream_moderation_enabled, type: :boolean, default: false
    settings.attribute :comments_upstream_moderation_enabled, type: :boolean, default: false
    settings.attribute :geocoding_enabled, type: :boolean, default: false
    settings.attribute :attachments_allowed, type: :boolean, default: false
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :new_participation_help_text, type: :text, translated: true, editor: true
  end

  feature.settings(:step) do |settings|
    settings.attribute :votes_enabled, type: :boolean
    settings.attribute :votes_blocked, type: :boolean
    settings.attribute :votes_hidden, type: :boolean, default: false
    settings.attribute :comments_blocked, type: :boolean, default: false
    settings.attribute :creation_enabled, type: :boolean
    settings.attribute :participation_answering_enabled, type: :boolean, default: true
    settings.attribute :announcement, type: :text, translated: true, editor: true
  end

  feature.register_resource do |resource|
    resource.model_class_name = "Decidim::Participations::Participation"
    resource.template = "decidim/participations/participations/linked_participations"
  end

  feature.register_stat :participations_count, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |features, start_at, end_at|
    Decidim::Participations::FilteredParticipations.for(features, start_at, end_at).not_hidden.authorized.count
  end

  feature.register_stat :participations_accepted, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |features, start_at, end_at|
    Decidim::Participations::FilteredParticipations.for(features, start_at, end_at).accepted.count
  end

  feature.register_stat :votes_count, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |features, start_at, end_at|
    participations = Decidim::Participations::FilteredParticipations.for(features, start_at, end_at).not_hidden
    Decidim::Participations::ParticipationVote.where(participation: participations).count
  end

  feature.register_stat :comments_count, tag: :comments do |features, start_at, end_at|
    participations = Decidim::Participations::FilteredParticipations.for(features, start_at, end_at).not_hidden
    Decidim::Comments::Comment.where(root_commentable: participations).count
  end

  feature.exports :participations do |exports|
    exports.collection do |feature_instance|
      Decidim::Participations::Participation
        .where(feature: feature_instance)
        .includes(:category, feature: { participatory_space: :organization })
    end

    exports.serializer Decidim::Participations::ParticipationSerializer
  end

  feature.exports :comments do |exports|
    exports.collection do |feature_instance|
      Decidim::Comments::Export.comments_for_resource(
        Decidim::Participations::Participation, feature_instance
      )
    end

    exports.serializer Decidim::Comments::CommentSerializer
  end

  feature.seeds do |participatory_space|
    step_settings = if participatory_space.allows_steps?
                      { participatory_space.active_step.id => { votes_enabled: true, votes_blocked: false, creation_enabled: true } }
                    else
                      {}
                    end

    feature = Decidim::Feature.create!(
      name: Decidim::Features::Namer.new(participatory_space.organization.available_locales, :participations).i18n_name,
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
      author = Decidim::User.where(organization: feature.organization).all.sample
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

      participation = Decidim::Participations::Participation.create!(
        feature: feature,
        category: participatory_space.categories.sample,
        scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
        title: Faker::Lorem.sentence(2),
        body: Faker::Lorem.paragraphs(2).join("\n"),
        author: author,
        user_group: user_group,
        state: state,
        answer: answer,
        answered_at: Time.current
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
          organization: feature.organization,
          tos_agreement: "1",
          confirmed_at: Time.current
        )

        Decidim::Participations::ParticipationVote.create!(participation: participation, author: author) unless participation.answered? && participation.rejected?
      end

      Decidim::Comments::Seed.comments_for(participation)
    end
  end
end
