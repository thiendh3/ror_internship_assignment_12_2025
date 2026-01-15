class Relationship < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :follower_id, presence: true
  validates :followed_id, presence: true

  after_create :notify_follow
  before_destroy :remove_follow_notification

  private

  def notify_follow
    NotificationService.create_follow_notification(self)
  end

  def remove_follow_notification
    notifications.destroy_all
  end
end
