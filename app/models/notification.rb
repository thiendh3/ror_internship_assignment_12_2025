class Notification < ApplicationRecord
  belongs_to :recipient, class_name: 'User'
  belongs_to :actor, class_name: 'User'
  belongs_to :notifiable, polymorphic: true
  
  validates :notification_type, presence: true, 
    inclusion: { in: %w[like comment mention follow] }
  
  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Mark notification as read
  def mark_as_read!
    update(read: true)
  end
  
  # Generate notification message
  def message
    case notification_type
    when 'like'
      "#{actor.name} liked your post"
    when 'comment'
      "#{actor.name} commented on your post"
    when 'mention'
      "#{actor.name} mentioned you in a post"
    when 'follow'
      "#{actor.name} started following you"
    end
  end
end
