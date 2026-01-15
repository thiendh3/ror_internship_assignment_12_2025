# frozen_string_literal: true

class NotificationService
  class << self
    def create_follow_notification(relationship)
      notification = Notification.create!(
        user: relationship.followed,
        notifiable: relationship,
        notification_type: 'follow'
      )
      broadcast_notification(notification)
      notification
    end

    def create_unfollow_notification(relationship)
      notification = Notification.create!(
        user: relationship.followed,
        notifiable: relationship,
        notification_type: 'unfollow'
      )
      broadcast_notification(notification)
      notification
    end

    private

    def broadcast_notification(notification)
      NotificationsChannel.broadcast_to(
        notification.user,
        {
          id: notification.id,
          type: notification.notification_type,
          actor: {
            id: notification.actor&.id,
            name: notification.actor&.name,
            email: notification.actor&.email
          },
          message: notification_message(notification),
          created_at: notification.created_at,
          read: notification.read
        }
      )
    end

    def notification_message(notification)
      actor_name = notification.actor&.name || 'Someone'
      case notification.notification_type
      when 'follow'
        "#{actor_name} started following you"
      when 'unfollow'
        "#{actor_name} unfollowed you"
      else
        'You have a new notification'
      end
    end
  end
end
