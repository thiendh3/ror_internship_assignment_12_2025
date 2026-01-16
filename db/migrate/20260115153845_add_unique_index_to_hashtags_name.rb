class AddUniqueIndexToHashtagsName < ActiveRecord::Migration[7.1]
  def change
    remove_index :hashtags, :name
    add_index :hashtags, :name, unique: true
  end
end
