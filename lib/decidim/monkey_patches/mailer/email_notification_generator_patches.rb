# frozen_string_literal: true

module EmailNotificationGeneratorPatch 

  # def generate
  #   Rails.logger.info ">>>>>>>>> generate " + resource.inspect
  #   return unless resource
  #   Rails.logger.info ">>>>>>>>> generate resource present"
  #   return unless event_class.types.include?(:email)
  #   Rails.logger.info ">>>>>>>>> generate event_class.types.include?(:email)"

  #   recipient_ids.each do |recipient_id|
  #     send_email_to(recipient_id)
  #   end
  # end

  def send_email_to(recipient_id)
    Rails.logger.info ">>>>>>>>> send_email_to " + recipient_id.inspect
    recipient = Decidim::User.where(id: recipient_id).first
    Rails.logger.info ">>>>>>>>> send_email_to recipient" + recipient.inspect

    return unless recipient
    Rails.logger.info ">>>>>>>>> send_email_to recipient.email_on_notification?" + recipient.email_on_notification?.inspect

    return unless recipient.email_on_notification?
    Rails.logger.info ">>>>>>>>> send_email_to @extra" + @extra.inspect
    if @extra[:question_attributed]
      Rails.logger.info ">>>>>>>>> question_attributed "
      send_new_question_attributed(recipient)
    elsif @extra[:new_content]
      send_new_content_received(recipient)
    else
      send_event_received(recipient)
    end
  end

  private 
  
  def send_new_question_attributed(recipient)
    NotificationMailer
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

puts "now"


Decidim::EmailNotificationGenerator.class_eval do
  prepend(EmailNotificationGeneratorPatch)

end

Decidim::EmailNotificationGenerator.hello