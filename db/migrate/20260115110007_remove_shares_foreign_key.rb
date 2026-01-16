# frozen_string_literal: true

class RemoveSharesForeignKey < ActiveRecord::Migration[7.1]
  def up
    # Remove foreign key constraint on shares.micropost_id
    remove_foreign_key :shares, :microposts, if_exists: true
  end

  def down
    add_foreign_key :shares, :microposts, if_not_exists: true
  end
end
