# frozen_string_literal: true

module EmailNotificationGeneratorPatch

  def send_email_to(recipient_id)
    recipient = Decidim::User.where(id: recipient_id).first
    return unless recipient
    return unless recipient.email_on_notification?
    Decidim::NotificationMailer
      .event_received(
        event,
        event_class.name,
        resource,
        recipient,
        extra
      ).deliver_later
  end
end

Decidim::EmailNotificationGenerator.class_eval do
  prepend(EmailNotificationGeneratorPatch)
end