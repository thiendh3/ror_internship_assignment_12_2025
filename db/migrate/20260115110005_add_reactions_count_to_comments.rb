# frozen_string_literal: true

class AddReactionsCountToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :reactions_count, :integer, default: 0, null: false
  end
end
