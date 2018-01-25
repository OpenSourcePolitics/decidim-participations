# frozen_string_literal: true

module EmailNotificationGeneratorPatch 

  def send_email_to(recipient_id)
    recipient = Decidim::User.where(id: recipient_id).first
    return unless recipient
    return unless recipient.email_on_notification?
    if @extra[:question_attributed]
      send_new_question_attributed(recipient)
    elsif @extra[:new_content]
      send_new_content_received(recipient)
    else
      send_event_received(recipient)
    end
  end

  private 
  
  def send_new_question_attributed(recipient)
    Decidim::NotificationMailer
    .new_question_attributed(
      event,
      event_class.name,
      resource,
      recipient,
      extra
    )
    .deliver_later
  end

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


end

Decidim::EmailNotificationGenerator.class_eval do
  prepend(EmailNotificationGeneratorPatch)
end