# frozen_string_literal: true

class Notification < ApplicationRecord
  TYPES = %w[
    follow unfollow
    comment reply
    micropost_reaction comment_reaction
    share
    new_post
  ].freeze

  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :notification_type, presence: true, inclusion: { in: TYPES }

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_notification

  # Get the actor (e.g., follower) from the notification
  def actor
    return nil unless notifiable

    case notification_type
    when 'follow', 'unfollow'
      notifiable.follower
    when 'comment', 'reply'
      notifiable.user
    when 'micropost_reaction', 'comment_reaction'
      notifiable.user
    when 'share'
      notifiable.user
    when 'new_post'
      notifiable.user
    end
  end

  def message
    return '' unless actor

    case notification_type
    when 'follow'
      'started following you'
    when 'unfollow'
      'unfollowed you'
    when 'comment'
      'commented on your post'
    when 'reply'
      'replied to your comment'
    when 'micropost_reaction'
      'reacted to your post'
    when 'comment_reaction'
      'reacted to your comment'
    when 'share'
      'shared your post'
    when 'new_post'
      'posted something new'
    else
      'You have a new notification'
    end
  end

  # Get the URL to redirect when clicking notification
  def target_url
    case notification_type
    when 'follow', 'unfollow'
      "/users/#{actor&.id}"
    when 'comment'
      "/microposts/#{notifiable.micropost_id}#comment-#{notifiable.id}"
    when 'reply'
      "/microposts/#{notifiable.micropost_id}#comment-#{notifiable.id}"
    when 'micropost_reaction'
      "/microposts/#{notifiable.reactable_id}"
    when 'comment_reaction'
      comment = notifiable.reactable
      "/microposts/#{comment.micropost_id}#comment-#{comment.id}"
    when 'share'
      "/users/#{notifiable.user_id}#micropost-#{notifiable.id}"
    when 'new_post'
      "/microposts/#{notifiable.id}"
    else
      '/notifications'
    end
  end

  # Get micropost id for quick access
  def related_micropost_id
    case notification_type
    when 'comment', 'reply'
      notifiable.micropost_id
    when 'micropost_reaction'
      notifiable.reactable_id if notifiable.reactable_type == 'Micropost'
    when 'comment_reaction'
      notifiable.reactable.micropost_id if notifiable.reactable_type == 'Comment'
    when 'share', 'new_post'
      notifiable.is_a?(Micropost) ? notifiable.id : notifiable.micropost_id
    end
  end

  private

  def broadcast_notification
    NotificationsChannel.broadcast_to(user, notification_data)
  rescue StandardError => e
    Rails.logger.error("Failed to broadcast notification: #{e.message}")
  end

  def notification_data
    {
      id: id,
      message: message,
      notification_type: notification_type,
      read: read,
      created_at: created_at,
      target_url: target_url,
      actor: actor ? { 
        id: actor.id, 
        name: actor.name,
        avatar_url: gravatar_url(actor)
      } : nil,
      micropost_id: related_micropost_id
    }
  end

  def gravatar_url(user, size = 40)
    require 'digest/md5'
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=identicon"
  end
end
