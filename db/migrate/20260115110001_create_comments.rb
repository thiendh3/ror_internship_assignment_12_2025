# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :micropost, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :comments }
      t.text :content, null: false

      t.timestamps
    end

    add_index :comments, [:micropost_id, :created_at]
  end
end
