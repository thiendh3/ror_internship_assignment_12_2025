class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :micropost, null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end
    
    add_index :comments, [:micropost_id, :created_at]
  end
end
