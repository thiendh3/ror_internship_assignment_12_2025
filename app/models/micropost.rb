class Micropost < ApplicationRecord
  # Searchkick for Elasticsearch full-text search
  searchkick word_start: [:content]

  # Associations
  belongs_to :user
  has_one_attached :image
  has_many :micropost_hashtags, dependent: :destroy
  has_many :hashtags, through: :micropost_hashtags
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user
  has_many :comments, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  # Scopes
  default_scope -> { order(created_at: :desc) }

  # Privacy enum (Rails 7+ syntax)
  enum :privacy, { public_post: 0, followers_only: 1, private_post: 2 }

  # Validations
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
  validates :image, content_type: { in: %w[image/jpeg image/gif image/png],
                                    message: 'must be a valid image format' },
                    size: { less_than: 5.megabytes,
                            message: 'should be less than 5MB' }

  # Callbacks
  after_commit :extract_and_save_hashtags, on: %i[create update]
  after_commit :create_mention_notifications, on: %i[create update]
  after_create_commit :broadcast_micropost

  # Return a resized image for display
  def display_image
    image.variant(resize_to_limit: [500, 500])
  end

  # Define searchable data for Searchkick
  def search_data
    {
      content: content,
      user_id: user_id,
      user_name: user.name,
      created_at: created_at,
      hashtags: hashtags.pluck(:name),
      privacy: privacy
    }
  end

  # Check if user liked this micropost
  def liked_by?(user)
    return false unless user

    likes.exists?(user_id: user.id)
  end

  # Get like for user
  def like_for(user)
    likes.find_by(user_id: user.id)
  end

  private

  def extract_and_save_hashtags
    HashtagExtractor.extract_and_associate(self)
  end

  def create_mention_notifications
    MentionExtractor.extract_and_notify(self)
  end

  def broadcast_micropost
    MicropostBroadcastJob.perform_later(self) if public_post?
  end
end
