class NotificationService
  # Create notification when someone likes a micropost
  def self.create_like_notification(liker, micropost)
    # Don't notify if user likes their own post
    return if liker.id == micropost.user_id
    
    # Check if notification already exists (avoid duplicates)
    existing = Notification.find_by(
      recipient_id: micropost.user_id,
      actor_id: liker.id,
      notifiable: micropost,
      notification_type: 'like'
    )
    
    return existing if existing
    
    # Create new notification
    notification = Notification.create(
      recipient_id: micropost.user_id,
      actor_id: liker.id,
      notifiable: micropost,
      notification_type: 'like',
      content: "#{liker.name} liked your post: #{micropost.content.truncate(50)}"
    )
    
    # Broadcast to recipient via WebSocket
    broadcast_notification(notification) if notification.persisted?
    
    notification
  end
  
  # Delete notification when someone unlikes
  def self.remove_like_notification(unliker, micropost)
    Notification.where(
      recipient_id: micropost.user_id,
      actor_id: unliker.id,
      notifiable: micropost,
      notification_type: 'like'
    ).destroy_all
  end
  
  private
  
  def self.broadcast_notification(notification)
    recipient = notification.recipient
    unread_count = recipient.notifications.unread.count
    
    NotificationChannel.broadcast_to(
      recipient,
      {
        id: notification.id,
        type: notification.notification_type,
        message: notification.message,
        actor: {
          id: notification.actor.id,
          name: notification.actor.name,
          gravatar_url: notification.actor.gravatar_url
        },
        notifiable: {
          id: notification.notifiable_id,
          type: notification.notifiable_type,
          content: notification.notifiable.respond_to?(:content) ? notification.notifiable.content : nil
        },
        created_at: notification.created_at,
        read: notification.read,
        unread_count: unread_count
      }
    )
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
