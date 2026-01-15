# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :notification_type, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Get the actor (e.g., follower) from the notification
  def actor
    return nil unless notifiable

    case notification_type
    when 'follow', 'unfollow'
      notifiable.follower
    end
  end
end
