class Relationship < ApplicationRecord
  belongs_to :follower, class_name: "User", counter_cache: :following_count
  belongs_to :followed, class_name: "User", counter_cache: :followers_count
  validates :follower_id, presence: true
  validates :followed_id, presence: true

  after_create_commit :notify_follow
  after_destroy_commit :notify_unfollow

  private
    def notify_follow
      NotificationService.create_notification(follower, "followed", followed, self)
    end

    def notify_unfollow
      NotificationService.create_notification(follower, "unfollowed", followed, nil)
    end
end
