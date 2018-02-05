# frozen_string_literal: true

module Decidim
  module Admin
    module Features
      # This controller is the abstract class from which all feature
      # controllers in their admin engines should inherit from.
      class CustomBaseController < Admin::ApplicationController
        skip_authorize_resource
        include Settings

        helper Decidim::ResourceHelper
        helper Decidim::Admin::ExportsHelper

        helper_method :current_feature,
                      :current_participatory_space,
                      :parent_path

        before_action do
          extend current_participatory_space.admin_extension_module
        end

        before_action :manage_authorization, except: [:index, :show]
        before_action :read_authorization, on: [:index, :show]

        def current_feature
          request.env["decidim.current_feature"]
        end

        def current_participatory_space
          current_feature.participatory_space
        end

        def parent_path
          @parent_path ||= EngineRouter.admin_proxy(current_participatory_space).features_path
        end

        protected 

        def manage_authorization
          authorize! :manage, current_feature
        end

        def read_authorization
          authorize! :read, current_feature
        end
      end
    end
  end
end
