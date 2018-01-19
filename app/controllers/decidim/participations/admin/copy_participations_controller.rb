module Decidim
    module Participations
      module Admin
        # This controller allows admins to answer participations in a participatory process.
        class CopyParticipationsController < Admin::ApplicationController
          helper_method :participation

          # Here we use show to copy the participations as all actions 
          #apart from index and show require to manage the current_feature
          def manage_authorization
            authorize! :duplicate, participation
          end
          

          def create
            
            Admin::CopyParticipation.call(@participation) do
              on(:ok) do
                flash[:notice] = I18n.t("participations.copy.success", scope: "decidim.participations.admin")
                redirect_to participations_path
              end
  
              on(:invalid) do
                flash.now[:alert] =  I18n.t("participations.copy.invalid", scope: "decidim.participations.admin")
                redirect_to participations_path
              end
            end
          end

          private
  
          def participation
            @participation ||= Participation.current_feature_participations(current_feature).find(params[:participation_id])
          end
        end
      end
    end
  end
  