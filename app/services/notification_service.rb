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

    # Create notification when someone follows a user
    def create_follow_notification(follower, followed_user)
      return if follower.id == followed_user.id # Don't notify self

      # Check if notification already exists to avoid duplicates
      existing_notification = Notification.find_by(
        recipient: followed_user,
        actor: follower,
        action: 'followed',
        notifiable_type: 'User',
        notifiable_id: followed_user.id
      )

      return if existing_notification

      Notification.create(
        recipient: followed_user,
        actor: follower,
        notifiable: followed_user,
        action: 'followed'
      )
    end

    # Create notification when someone unfollows a user (optional)
    def create_unfollow_notification(unfollower, unfollowed_user)
      return if unfollower.id == unfollowed_user.id # Don't notify self

      Notification.create(
        recipient: unfollowed_user,
        actor: unfollower,
        notifiable: unfollowed_user,
        action: 'unfollowed'
      )
    end
  end
end
