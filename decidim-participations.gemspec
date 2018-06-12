# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "decidim/participations/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.version = Decidim::Participations.version
  s.authors = ["Josep Jaume Rey Peroy", "Marc Riera Casals", "Oriol Gual Oliva"]
  s.email = ["josepjaume@gmail.com", "mrc2407@gmail.com", "oriolgual@gmail.com"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/decidim/decidim"
  s.required_ruby_version = ">= 2.3"

  s.name = "decidim-participations"
  s.summary = "A participations component for decidim's participatory processes."
  s.description = s.summary

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  s.add_dependency "cells-erb", "~> 0.1.0"
  s.add_dependency "cells-rails", "~> 0.0.9"
  s.add_dependency "decidim-comments", Decidim::Participations.version
  s.add_dependency "decidim-core", Decidim::Participations.version
  s.add_dependency "kaminari", "~> 1.0"
  s.add_dependency "ransack", "~> 1.8"
  s.add_dependency "social-share-button", "~> 1.0"

  s.add_development_dependency "decidim-admin", Decidim::Participations.version
  s.add_development_dependency "decidim-assemblies", Decidim::Participations.version
  s.add_development_dependency "decidim-budgets", Decidim::Participations.version
  s.add_development_dependency "decidim-dev", Decidim::Participations.version
  s.add_development_dependency "decidim-meetings", Decidim::Participations.version
  s.add_development_dependency "decidim-participatory_processes", Decidim::Participations.version
end
