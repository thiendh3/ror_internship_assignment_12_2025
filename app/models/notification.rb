class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true, optional: true

  after_create_commit :broadcast_notification

  private
    def broadcast_notification
      gravatar_id = Digest::MD5::hexdigest(actor.email.downcase)
      avatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=30"
      actor_url = Rails.application.routes.url_helpers.user_path(actor)

      NotificationChannel.broadcast_to(
        recipient,
        {
          action: action,
          actor_name: actor.name,
          actor_avatar_url: avatar_url,
          actor_url: actor_url,
          notifiable_type: notifiable_type,
          created_at: created_at.strftime("%b %d, %H:%M")
        }
      )
    end
end
