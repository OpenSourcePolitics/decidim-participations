# frozen_string_literal: true
module NotificationMailerPatch

  def event_received(event, event_class_name, resource, user, extra)
    if extra[:template]
      send_custom_email(event, event_class_name, resource, user, extra)
    else
      with_user(user) do
          @organization = resource.organization
          event_class = event_class_name.constantize
          @event_instance = event_class.new(resource: resource, event_name: event, user: user, extra: extra)
          subject = @event_instance.email_subject
          mail(to: user.email, subject: subject)
      end
    end
  end 

  def send_custom_email(event, event_class_name, resource, user, extra)
    with_user(user) do
      @organization = resource.organization
      event_class = event_class_name.constantize
      @event_instance = event_class.new(resource: resource, event_name: event, user: user, extra: extra)
      subject = @event_instance.email_subject

      mail(to: user.email, subject: subject, template_name: extra[:template])
    end
  end
end

Decidim::NotificationMailer.class_eval do
  prepend(NotificationMailerPatch)
end
