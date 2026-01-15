# frozen_string_literal: true

class Reaction < ApplicationRecord
  REACTION_TYPES = %w[like love haha wow sad angry].freeze

  belongs_to :user
  belongs_to :reactable, polymorphic: true, counter_cache: :reactions_count
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :reaction_type, presence: true, inclusion: { in: REACTION_TYPES }
  validates :user_id, uniqueness: { scope: [:reactable_type, :reactable_id] }

  after_create_commit :notify_owner

  private

  def notify_owner
    owner = reactable.user
    return if user_id == owner.id

    Notification.create!(
      user: owner,
      notifiable: self,
      notification_type: "#{reactable_type.underscore}_reaction"
    )
  end
end
