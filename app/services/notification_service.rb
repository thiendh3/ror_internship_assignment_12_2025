class NotificationService
  # Create notification when someone reacts to a micropost
  def self.create_like_notification(liker, micropost, reaction_type = 'like')
    # Don't notify if user reacts to their own post
    return if liker.id == micropost.user_id

    reaction_type = reaction_type.to_s

    existing = Notification.find_by(
      recipient_id: micropost.user_id,
      actor_id: liker.id,
      notifiable: micropost,
      notification_type: %w[like love haha]
    )

    if existing
      existing.update(
        notification_type: reaction_type,
        content: reaction_message(liker, micropost, reaction_type)
      )
      broadcast_notification(existing)
      return existing
    end

    notification = Notification.create(
      recipient_id: micropost.user_id,
      actor_id: liker.id,
      notifiable: micropost,
      notification_type: reaction_type,
      content: reaction_message(liker, micropost, reaction_type)
    )

    broadcast_notification(notification) if notification.persisted?

    notification
  end

  # Delete notification when someone removes reaction
  def self.remove_like_notification(unliker, micropost)
    Notification.where(
      recipient_id: micropost.user_id,
      actor_id: unliker.id,
      notifiable: micropost,
      notification_type: %w[like love haha]
    ).destroy_all
  end

  def self.broadcast_notification(notification)
    recipient = notification.recipient
    unread_count = recipient.notifications.unread.count

    NotificationChannel.broadcast_to(
      recipient,
      build_notification_payload(notification, unread_count)
    )
  end

  def self.build_notification_payload(notification, unread_count)
    {
      id: notification.id,
      type: notification.notification_type,
      message: notification.message,
      actor: build_actor_data(notification.actor),
      notifiable: build_notifiable_data(notification.notifiable, notification.notifiable_type),
      created_at: notification.created_at,
      read: notification.read,
      unread_count: unread_count
    }
  end

  def self.build_actor_data(actor)
    {
      id: actor.id,
      name: actor.name,
      gravatar_url: actor.gravatar_url
    }
  end

  def self.build_notifiable_data(notifiable, notifiable_type)
    {
      id: notifiable.id,
      type: notifiable_type,
      content: notifiable.respond_to?(:content) ? notifiable.content : nil
    }
  end

  def self.reaction_message(liker, micropost, reaction_type)
    verb = case reaction_type
           when 'love'
             'loved'
           when 'haha'
             'reacted 😂 to'
           else
             'liked'
           end

    "#{liker.name} #{verb} your post: #{micropost.content.truncate(50)}"
  end

  # Create notification when someone comments
  def self.create_comment_notification(commenter, micropost, comment)
    return if commenter.id == micropost.user_id

    notification = Notification.create(
      recipient_id: micropost.user_id,
      actor_id: commenter.id,
      notifiable: comment,
      notification_type: 'comment',
      content: "#{commenter.name} commented on your post: #{comment.content.truncate(50)}"
    )

    # Broadcast to recipient via WebSocket
    broadcast_notification(notification) if notification.persisted?

    notification
  end

  # Create notification when someone mentions you
  def self.create_mention_notification(mentioner, mentioned_user, micropost)
    return if mentioner.id == mentioned_user.id

    # Check if notification already exists (avoid duplicates)
    existing = Notification.find_by(
      recipient_id: mentioned_user.id,
      actor_id: mentioner.id,
      notifiable: micropost,
      notification_type: 'mention'
    )

    return existing if existing

    notification = Notification.create(
      recipient_id: mentioned_user.id,
      actor_id: mentioner.id,
      notifiable: micropost,
      notification_type: 'mention',
      content: "#{mentioner.name} mentioned you in a post: #{micropost.content.truncate(50)}"
    )

    # Broadcast to recipient via WebSocket
    broadcast_notification(notification) if notification.persisted?

    notification
  end
end
