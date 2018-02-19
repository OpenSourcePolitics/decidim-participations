# frozen_string_literal: true

module NotificationGeneratorPatch
  def generate_notification_for(recipient_id)
    binding.pry
    NotificationGeneratorForRecipientJob.perform_in(extra[:edit_time_limit],
      event,
      event_class.name,
      resource,
      recipient_id,
      extra
    )
  end
end

Decidim::NotificationGenerator.class_eval do
  prepend(NotificationGeneratorPatch)
end
