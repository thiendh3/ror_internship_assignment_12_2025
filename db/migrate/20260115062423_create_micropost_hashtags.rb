class CreateMicropostHashtags < ActiveRecord::Migration[7.2]
  def change
    create_table :micropost_hashtags do |t|
      t.references :micropost, null: false, foreign_key: true
      t.references :hashtag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :micropost_hashtags, [:micropost_id, :hashtag_id], unique: true
  end
end
