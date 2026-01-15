class AddCounterCacheToMicroposts < ActiveRecord::Migration[7.2]
  def change
    add_column :microposts, :likes_count, :integer, default: 0, null: false
    add_column :microposts, :comments_count, :integer, default: 0, null: false
  end
end
