class RemoveNotNullOnTitle < ActiveRecord::Migration[5.1]
  def change
    change_column :decidim_participations_participations, :title, :string, null: true
  end
end
