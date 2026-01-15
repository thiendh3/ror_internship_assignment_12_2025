class Micropost < ApplicationRecord
  belongs_to :user
  belongs_to :original_post, class_name: 'Micropost', optional: true
  has_one_attached :image
  has_many :versions, class_name: 'MicropostVersion', dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :reactions, as: :reactable, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy
 
  has_many :shared_posts, class_name: 'Micropost', foreign_key: 'original_post_id'

  before_update :save_version
  before_destroy :decrement_original_shares_count
  default_scope -> { order(created_at: :desc) }
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }, unless: :shared_post?

  # Check if this is a shared post
  def shared_post?
    original_post_id.present?
  end

  # Get the original post (handles nested shares - always return root)
  def root_post
    return self unless shared_post?
    original_post&.root_post || original_post || self
  end
  validates :image, content_type: { in: %w[image/jpeg image/gif image/png],
                                    message: 'must be a valid image format' },
                    size: { less_than: 5.megabytes,
                            message: 'should be less than 5MB' }

  # Sunspot searchable configuration
  searchable do
    text :content
    integer :user_id
    text :user_name do
      user.name
    end
    time :created_at
  end

  # Auto-reindex when micropost is created or updated
  after_commit :reindex_to_solr, on: %i[create update]
  after_commit :notify_followers, on: :create

  # Reindex when micropost is destroyed
  after_commit :remove_from_solr, on: :destroy

  # Return a resized image for display
  def display_image
    image.variant(resize_to_limit: [500, 500])
  end

  private

  def save_version
    return unless content_changed?

    versions.create!(
      content: content_was,
      edited_at: updated_at || created_at
    )
  end

  # Reindex micropost to Solr
  def reindex_to_solr
    Sunspot.index(self)
  rescue StandardError => e
    Rails.logger.error("Failed to index micropost #{id}: #{e.message}")
  end

  # Remove micropost from Solr index
  def remove_from_solr
    Sunspot.remove(self)
  rescue StandardError => e
    Rails.logger.error("Failed to remove micropost #{id} from index: #{e.message}")
  end

  # Notify followers when a new post is created
  def notify_followers
    user.followers.find_each do |follower|
      Notification.create!(
        user: follower,
        notifiable: self,
        notification_type: 'new_post'
      )
    end
  rescue StandardError => e
    Rails.logger.error("Failed to notify followers for micropost #{id}: #{e.message}")
  end

  # Decrement shares_count when a shared post is destroyed
  def decrement_original_shares_count
    return unless shared_post? && original_post.present?

    original_post.decrement!(:shares_count)
  rescue StandardError => e
    Rails.logger.error("Failed to decrement shares_count: #{e.message}")
  end
end
