class AddOriginalBodyToDecidimParticipationsParticipations < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_participations_participations, :original_body, :text
  end
end
