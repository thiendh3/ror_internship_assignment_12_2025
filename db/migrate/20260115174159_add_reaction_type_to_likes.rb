class AddReactionTypeToLikes < ActiveRecord::Migration[7.1]
  def change
    add_column :likes, :reaction_type, :integer, default: 0, null: false
    add_index :likes, :reaction_type
  end
end
