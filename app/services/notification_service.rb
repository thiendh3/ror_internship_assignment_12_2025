class NotificationService
  class << self
    # Create notification when someone likes a micropost
    def create_like_notification(liker, micropost)
      return if liker.id == micropost.user_id # Don't notify self

      Notification.create(
        recipient: micropost.user,
        actor: liker,
        notifiable: micropost,
        action: 'liked'
      )
    end

    # Create notification when someone comments on a micropost
    def create_comment_notification(commenter, micropost, comment)
      return if commenter.id == micropost.user_id # Don't notify self

      Notification.create(
        recipient: micropost.user,
        actor: commenter,
        notifiable: comment,
        action: 'commented'
      )
    end

    # Create notification when someone mentions a user
    def create_mention_notification(mentioner, mentioned_user, micropost)
      Notification.create(
        recipient: mentioned_user,
        actor: mentioner,
        notifiable: micropost,
        action: 'mentioned'
      )
    end
  end
end
