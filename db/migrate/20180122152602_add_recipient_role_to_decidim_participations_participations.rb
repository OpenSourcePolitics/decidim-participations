class AddRecipientRoleToDecidimParticipationsParticipations < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_participations_participations, :recipient_role, :string
  end
end
