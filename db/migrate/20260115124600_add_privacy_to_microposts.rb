class AddPrivacyToMicroposts < ActiveRecord::Migration[7.1]
  def change
    add_column :microposts, :privacy, :integer, default: 0, null: false
    add_index :microposts, :privacy
  end
end
