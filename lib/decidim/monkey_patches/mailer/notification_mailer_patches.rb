# frozen_string_literal: true
module NotificationMailerPatch

  def event_received(event, event_class_name, resource, user, extra) # To avoid event_received from Core to override all of our methods, we use event_received as default method then redirect to corresponding custom method when it's needed.
    if extra[:participation_moderated]
      participation_moderated(event, event_class_name, resource, user, extra)
    else
      with_user(user) do
          @organization = resource.organization
          event_class = event_class_name.constantize
          @event_instance = event_class.new(resource: resource, event_name: event, user: user, extra: extra)
          subject = @event_instance.email_subject
          @template = extra[:template]
          mail(to: user.email, subject: subject)
      end
    end
  end

  def participation_moderated(event, event_class_name, resource, user, extra)
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
