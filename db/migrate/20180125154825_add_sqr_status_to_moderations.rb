class AddSqrStatusToModerations < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_moderations, :sqr_status, :string, default: "unmoderate"
  end
end
