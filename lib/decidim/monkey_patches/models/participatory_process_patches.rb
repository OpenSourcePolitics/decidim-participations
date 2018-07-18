module ParticipatoryProcessPatch
  def has_participation_component?
    components.where(manifest_name: "participations").any?
  end

  def participations_component
    i = components.index { |i| i["manifest_name"] == "participations" }
    components[i]
  end

  def can_be_managed_by?(current_user)
    Decidim::ParticipatoryProcessUserRole.where(user: current_user, role: "moderator").any? || Decidim::ParticipatoryProcessUserRole.where(user: current_user, role: "cpdp").any?
  end
end

Decidim::ParticipatoryProcess.class_eval do
  prepend(ParticipatoryProcessPatch)
end
