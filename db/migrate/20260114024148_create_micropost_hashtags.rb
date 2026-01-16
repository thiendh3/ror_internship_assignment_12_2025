class CreateMicropostHashtags < ActiveRecord::Migration[7.1]
  def change
    create_table :micropost_hashtags do |t|
      t.references :micropost, null: false, foreign_key: true
      t.references :hashtag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
