# frozen_string_literal: true

class AddReferenceToParticipations < ActiveRecord::Migration[5.0]
  class Participation < ApplicationRecord
    self.table_name = :decidim_participations_participations
  end

  def change
    add_column :decidim_participations_participations, :reference, :string
    Participation.find_each(&:save)
    change_column_null :decidim_participations_participations, :reference, false
  end
end
