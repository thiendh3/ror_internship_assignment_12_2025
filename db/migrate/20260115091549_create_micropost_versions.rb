class CreateMicropostVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :micropost_versions do |t|
      t.references :micropost, null: false, foreign_key: true
      t.text :content
      t.datetime :edited_at

      t.timestamps
    end
  end
end
