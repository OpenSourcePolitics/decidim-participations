begin
    require 'decidim/monkey_patches/mailer/email_notification_generator_patches.rb'
    require 'decidim/monkey_patches/mailer/notification_mailer_patches.rb'
  rescue LoadError
    puts "Monkey patches were not loaded"
  end
