class AddDeadLineToParticipations < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_participations_participations, :answer_deadline, :date
  end
end
