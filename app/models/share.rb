# frozen_string_literal: true

class Share < ApplicationRecord
  SHARE_TYPES = %w[share share_to_story].freeze

  belongs_to :user
  belongs_to :micropost, counter_cache: true, optional: true # original post being shared, optional allows null when deleted
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :share_type, inclusion: { in: SHARE_TYPES }
  validates :content, length: { maximum: 500 }, allow_blank: true

  default_scope -> { order(created_at: :desc) }

  after_create_commit :notify_post_owner

  # Get original post author
  def original_author
    micropost&.user
  end

  # Check if original post still exists
  def original_available?
    micropost.present?
  end

  private

  def notify_post_owner
    return unless micropost.present?
    return if user_id == micropost.user_id

    Notification.create!(
      user: micropost.user,
      notifiable: self,
      notification_type: 'share'
    )
  end
end
