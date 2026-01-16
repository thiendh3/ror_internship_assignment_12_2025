# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :micropost, counter_cache: true
  belongs_to :parent, class_name: 'Comment', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy
  has_many :reactions, as: :reactable, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :content, presence: true, length: { maximum: 500 }

  scope :root_comments, -> { where(parent_id: nil) }
  scope :recent, -> { order(created_at: :asc) }

  after_create_commit :notify_post_owner
  after_create_commit :notify_parent_comment_owner

  def nested_level
    level = 0
    current = self
    while current.parent
      level += 1
      current = current.parent
    end
    level
  end

  private

  def notify_post_owner
    return if user_id == micropost.user_id

    Notification.create!(
      user: micropost.user,
      notifiable: self,
      notification_type: 'comment'
    )
  end

  def notify_parent_comment_owner
    return unless parent
    return if user_id == parent.user_id

    Notification.create!(
      user: parent.user,
      notifiable: self,
      notification_type: 'reply'
    )
  end
end
