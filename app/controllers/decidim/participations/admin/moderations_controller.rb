# frozen_string_literal: true

module Decidim
  module Participations
    module Admin
      # This controller is the abstract class from which all other controllers of
      # this engine inherit.
      #
      # Note that it inherits from `Decidim::Admin::Features::BaseController`, which
      # override its layout and provide all kinds of useful methods.
      class ModerationController < Admin::ApplicationController
        def update
          @form = form(Admin::ModerationForm).from_params(params)
          moderation = Decidim::Moderation.find(params[:id])
          if @form.valid?
            blog = moderation.update_attributes(@form)
          else
            render "participations/edit"
          end
        end
      end
    end
  end
end
