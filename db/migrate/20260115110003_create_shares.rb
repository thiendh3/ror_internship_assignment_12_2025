# frozen_string_literal: true

class CreateShares < ActiveRecord::Migration[7.1]
  def change
    create_table :shares do |t|
      t.references :user, null: false, foreign_key: true
      t.references :micropost, null: false, foreign_key: true # original post
      t.text :content # optional caption when sharing
      t.string :share_type, default: 'share'

      t.timestamps
    end

    add_index :shares, [:user_id, :created_at]
  end
end
