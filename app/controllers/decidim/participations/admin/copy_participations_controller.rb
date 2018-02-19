module Decidim
    module Participations
      module Admin
        class CopyParticipationsController <  Decidim::Admin::Features::CustomBaseController
          helper_method :participation



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

          protected
          # Here we use show to copy the participations as all actions
          #apart from index and show require to manage the current_feature
          def manage_authorization
            authorize! :duplicate, participation
          end

        end
      end
    end
  end
