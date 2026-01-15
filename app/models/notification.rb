class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  after_create_commit :broadcast_notification

  private
    def broadcast_notification
      NotificationChannel.broadcast_to(
        recipient,
        {
          action: action,
          actor_name: actor.name,
          notifiable_type: notifiable_type,
          created_at: created_at.strftime("%b %d, %H:%M")
        }
      )
    end
end
