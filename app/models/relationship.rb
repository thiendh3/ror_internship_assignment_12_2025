class Relationship < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"
  validates :follower_id, presence: true
  validates :followed_id, presence: true

  after_create_commit :create_notification

  private
    def create_notification
      Notification.create(
        recipient: followed,
        actor: follower,
        action: "followed",
        notifiable: self
      )
    end
end
