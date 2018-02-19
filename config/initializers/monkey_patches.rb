begin
    require 'decidim/monkey_patches/mailer/notification_mailer_patches.rb'
    require 'decidim/monkey_patches/mailer/notification_generator_patches.rb'
  rescue LoadError
    puts "Monkey patches were not loaded"
  end
