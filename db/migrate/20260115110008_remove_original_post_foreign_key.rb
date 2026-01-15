# frozen_string_literal: true

class RemoveOriginalPostForeignKey < ActiveRecord::Migration[7.1]
  def up
    remove_foreign_key :microposts, column: :original_post_id, if_exists: true
  end

  def down
    add_foreign_key :microposts, :microposts, column: :original_post_id, if_not_exists: true
  end
end
