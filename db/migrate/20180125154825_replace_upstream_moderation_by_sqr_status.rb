class ReplaceUpstreamModerationBySqrStatus < ActiveRecord::Migration[5.1]
  def change
    rename_column :decidim_participations_participations, :upstream_moderation, :sqr_status
  end
end
