class NotificationBroadcastJob < ApplicationJob
  queue_as :default

  def perform(notification)
    ActionCable.server.broadcast(
      "notifications_#{notification.recipient_id}",
      {
        id: notification.id,
        message: notification.message,
        action: notification.action,
        read: notification.read,
        created_at: notification.created_at,
        actor: {
          id: notification.actor.id,
          name: notification.actor.name
        },
        notifiable: {
          id: notification.notifiable_id,
          type: notification.notifiable_type
        }
      }
    )
  end
end
