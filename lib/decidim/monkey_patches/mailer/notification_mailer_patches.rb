# frozen_string_literal: true
module NotificationMailerPatch

    def event_received(event, event_class_name, resource, user, extra)
      with_user(user) do
          @organization = resource.organization
          event_class = event_class_name.constantize
          @event_instance = event_class.new(resource: resource, event_name: event, user: user, extra: extra)
          subject = @event_instance.email_subject
          @template = extra[:template]
          mail(to: user.email, subject: subject)
      end
    end

    def participation_moderated(event, event_class_name, resource, user, extra)
      with_user(user) do
          @organization = resource.organization
          event_class = event_class_name.constantize
          @event_instance = event_class.new(resource: resource, event_name: event, user: user, extra: extra)
          @justification = extra[:justification]

          subject = @event_instance.email_subject

          mail(to: user.email, subject: subject, template_name: extra[:template])
      end
    end


end

Decidim::NotificationMailer.class_eval do
    prepend(NotificationMailerPatch)
end
