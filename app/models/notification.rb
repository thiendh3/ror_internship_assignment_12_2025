class Notification < ApplicationRecord
  belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_id'
  belongs_to :actor, class_name: 'User', foreign_key: 'actor_id'
  belongs_to :notifiable, polymorphic: true

  validates :action, presence: true

  # Callbacks
  after_create_commit :broadcast_notification

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Mark notification as read
  def mark_as_read!
    update(read: true)
  end

  # Get notification message based on action
  def message
    case action
    when 'liked'
      "#{actor.name} liked your micropost"
    when 'commented'
      "#{actor.name} commented on your micropost"
    when 'mentioned'
      "#{actor.name} mentioned you in a micropost"
    when 'followed'
      "#{actor.name} started following you"
    when 'unfollowed'
      "#{actor.name} unfollowed you"
    else
      "#{actor.name} #{action}"
    end
  end

  # Get URL to navigate to based on notification type
  def url
    case action
    when 'liked', 'commented', 'mentioned'
      # Navigate to the micropost
      if notifiable_type == 'Micropost'
        "/microposts/#{notifiable_id}"
      elsif notifiable_type == 'Comment'
        # If it's a comment, get the micropost from the comment
        comment = Comment.find_by(id: notifiable_id)
        comment ? "/microposts/#{comment.micropost_id}" : '/'
      else
        '/'
      end
    when 'followed', 'unfollowed'
      # Navigate to the actor's profile
      "/users/#{actor.id}"
    else
      '/'
    end
  rescue StandardError
    '/'
  end

  private

  def broadcast_notification
    NotificationBroadcastJob.perform_later(self)
  end
end
