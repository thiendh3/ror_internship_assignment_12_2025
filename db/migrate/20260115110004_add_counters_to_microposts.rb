# frozen_string_literal: true

class AddCountersToMicroposts < ActiveRecord::Migration[7.1]
  def change
    add_column :microposts, :comments_count, :integer, default: 0, null: false
    add_column :microposts, :reactions_count, :integer, default: 0, null: false
    add_column :microposts, :shares_count, :integer, default: 0, null: false
  end
end
