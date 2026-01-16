class Relationship < ApplicationRecord
  belongs_to :follower, class_name: 'User', counter_cache: :following_count
  belongs_to :followed, class_name: 'User', counter_cache: :followers_count
  validates :follower_id, presence: true
  validates :followed_id, presence: true

  after_create_commit :notify_follow
  after_destroy_commit :notify_unfollow

  after_commit :broadcast_stats_update, on: %i[create destroy]

  private

  def notify_follow
    NotificationService.create_notification(follower, 'followed', followed, self)
  end

  def notify_unfollow
    NotificationService.create_notification(follower, 'unfollowed', followed, nil)
  end

  def broadcast_stats_update
    # 1. Update the 'Followed' User (The one getting a new follower)
    # Reload to ensure we get the latest counter_cache value from DB
    followed.reload
    broadcast_update_to "user_stats_#{followed.id}",
                        target: "followers-#{followed.id}",
                        html: followed.followers_count

    # Also update the Modal count if it's open
    broadcast_update_to "user_stats_#{followed.id}",
                        target: "modal-followers-#{followed.id}",
                        html: followed.followers_count

    # 2. Update the 'Follower' User (The one who clicked follow)
    follower.reload
    broadcast_update_to "user_stats_#{follower.id}",
                        target: "following-#{follower.id}",
                        html: follower.following_count
  end
end
