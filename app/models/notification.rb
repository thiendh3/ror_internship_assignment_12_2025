class Notification < ApplicationRecord
  belongs_to :recipient, class_name: 'User'
  belongs_to :actor, class_name: 'User'
  belongs_to :notifiable, polymorphic: true, optional: true
  validates :recipient_id, :actor_id, :action, presence: true
end
