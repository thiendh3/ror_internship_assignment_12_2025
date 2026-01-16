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
      actor = notification.actor
      NotificationsChannel.broadcast_to(
        notification.user,
        {
          id: notification.id,
          type: notification.notification_type,
          actor: actor ? {
            id: actor.id,
            name: actor.name,
            email: actor.email,
            avatar_url: gravatar_url(actor)
          } : nil,
          message: notification.message,
          target_url: notification.target_url,
          created_at: notification.created_at,
          read: notification.read
        }
      )
    end

    def gravatar_url(user, size = 40)
      require 'digest/md5'
      gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
      "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=identicon"
    end

  end
end
