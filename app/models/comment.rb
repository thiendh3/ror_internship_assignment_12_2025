class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :micropost, counter_cache: true

  validates :content, presence: true, length: { maximum: 500 }

  # Trigger notification after create
  after_create_commit :create_notification

  private

  def create_notification
    NotificationService.create_comment_notification(user, micropost, self)
  end
end
