# frozen_string_literal: true

module EmailNotificationGeneratorPatch

  def send_email_to(recipient_id)
    recipient = Decidim::User.where(id: recipient_id).first
    return unless recipient
    return unless recipient.email_on_notification?
    if @extra[:template] || @extra[:question_attributed]
      Decidim::NotificationMailer
      .send_custom_email(
        event,
        event_class.name,
        resource,
        recipient,
        extra
      )
      .deliver_later
    elsif @extra[:new_content]
      send_new_content_received(recipient)
    elsif @extra[:participation_moderated]
      send_participation_moderated(recipient)
    else
      send_event_received(recipient)
    end
  end

  private

  def send_new_content_received(recipient)
    NotificationMailer
    .new_content_received(
      event,
      event_class.name,
      resource,
      recipient,
      extra
    )
    .deliver_later
  end

  def send_event_received(recipient)
    NotificationMailer
    .event_received(
      event,
      event_class.name,
      resource,
      recipient,
      extra
    )
    .deliver_later
  end

  def send_participation_moderated(recipient)
    NotificationMailer
    .participation_moderated(
      event,
      event_class.name,
      resource,
      recipient,
      extra
    )
    .deliver_later
  end
end

Decidim::EmailNotificationGenerator.class_eval do
  prepend(EmailNotificationGeneratorPatch)
end