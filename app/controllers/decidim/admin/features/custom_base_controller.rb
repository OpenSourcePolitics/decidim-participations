# frozen_string_literal: true

module Decidim
  module Admin
    module Components
      # This controller is the abstract class from which all component
      # controllers in their admin engines should inherit from.
      class CustomBaseController < Admin::ApplicationController
        skip_authorize_resource
        include Settings
        include Decidim::Admin::ParticipatorySpaceAdminContext

        helper Decidim::ResourceHelper
        helper Decidim::Admin::ExportsHelper

        helper_method :current_component,
                      :current_participatory_space,
                      :parent_path


        before_action :manage_authorization, except: [:index, :show]
        before_action :read_authorization, on: [:index, :show]

        def current_component
          request.env["decidim.current_component"]
        end

        def current_participatory_space
          current_component.participatory_space
        end

        def parent_path
          @parent_path ||= EngineRouter.admin_proxy(current_participatory_space).components_path
        end

        protected

        def manage_authorization
          authorize! :manage, current_component
        end

        def read_authorization
          authorize! :read, current_component
        end
      end
    end
  end
end
