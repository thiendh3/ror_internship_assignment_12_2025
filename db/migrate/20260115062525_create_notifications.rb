class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true, null: false
      t.string :action, null: false
      t.boolean :read, default: false, null: false

      t.timestamps
    end
    add_index :notifications, [:recipient_id, :read, :created_at]
    add_index :notifications, [:notifiable_type, :notifiable_id]
  end
end
