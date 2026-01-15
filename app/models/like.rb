class Like < ApplicationRecord
  belongs_to :user
  belongs_to :micropost, counter_cache: true

  validates :user_id, uniqueness: { scope: :micropost_id, message: 'has already liked this micropost' }

  # Trigger notification after create
  after_create_commit :create_notification

  private

  def create_notification
    NotificationService.create_like_notification(user, micropost)
  end
end
