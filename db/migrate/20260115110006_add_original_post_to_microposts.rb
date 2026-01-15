# frozen_string_literal: true

class AddOriginalPostToMicroposts < ActiveRecord::Migration[7.1]
  def change
    add_reference :microposts, :original_post, foreign_key: { to_table: :microposts }, null: true
  end
end
