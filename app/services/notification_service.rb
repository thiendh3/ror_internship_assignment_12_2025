class NotificationService
  class << self
    def create_notification(actor, action, recipient, notifiable = nil)
      notification = Notification.new(
        actor: actor,
        action: action,
        recipient: recipient,
        notifiable: notifiable
      )

      if notification.save
        broadcast_notification(notification)
        notification
      end
    end

    private

    def broadcast_notification(notification)
      actor = notification.actor
      gravatar_id = Digest::MD5::hexdigest(actor.email.downcase)
      avatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=30"
      actor_url = Rails.application.routes.url_helpers.user_path(actor)

      NotificationChannel.broadcast_to(
        notification.recipient,
        {
          action: notification.action,
          actor_name: actor.name,
          actor_avatar_url: avatar_url,
          actor_url: actor_url,
          created_at: notification.created_at.strftime("%b %d, %H:%M")
        }
      )
    end
  end
end