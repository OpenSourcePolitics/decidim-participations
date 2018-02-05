class AddJustificationToModeration < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_moderations, :justification, :text
  end
end
