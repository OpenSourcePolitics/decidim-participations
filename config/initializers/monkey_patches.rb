begin
    require 'decidim/monkey_patches/mailer/notification_mailer_patches.rb'
    require 'decidim/monkey_patches/models/participatory_process_patches.rb'
  rescue LoadError
    puts "Monkey patches were not loaded"
  end
