class Micropost < ApplicationRecord
  after_destroy :remove_from_solr
  after_save :extract_and_save_hashtags
  after_save :extract_and_notify_mentions
  after_commit :index_to_solr

  belongs_to :user

  has_many :micropost_hashtags, dependent: :destroy
  has_many :hashtags, through: :micropost_hashtags

  has_many :likes, dependent: :destroy
  has_many :liked_by_users, through: :likes, source: :user
  has_many :comments, dependent: :destroy

  has_one_attached :image

  # Privacy levels: public (0), friends_only (1), only_me (2)
  enum :privacy, { public_post: 0, friends_only: 1, only_me: 2 }

  default_scope -> { order(created_at: :desc) }
  validates :content, presence: true, length: { maximum: 140 }
  validates :image, content_type: { in: %w[image/jpeg image/gif image/png],
                                    message: 'must be a valid image format' },
                    size: { less_than: 5.megabytes,
                            message: 'should be less than 5MB' }

  # Return a resized image for display
  def display_image
    image.variant(resize_to_limit: [500, 500])
  end

  def display_image_url
    return nil unless image.attached?

    Rails.application.routes.url_helpers.rails_blob_path(display_image, only_path: true)
  end

  delegate :count, to: :likes, prefix: true

  def liked_by?(user)
    return false unless user

    likes.exists?(user_id: user.id)
  end

  def reaction_for(user)
    return nil unless user

    likes.find_by(user_id: user.id)&.reaction_type
  end

  def reaction_counts
    likes.group(:reaction_type).count
  end

  def like!(user, reaction_type = :like)
    likes.create!(user_id: user.id, reaction_type: reaction_type)
  end

  def unlike!(user)
    likes.find_by(user_id: user.id)&.destroy
  end

  HASHTAG_REGEX = /#\w+/
  MENTION_REGEX = /@(\w+)/

  def extract_hashtags
    content.scan(HASHTAG_REGEX).map(&:downcase).uniq
  end

  def extract_mentions
    content.scan(MENTION_REGEX).map(&:first).uniq
  end

  def content_without_hashtags
    content.gsub(HASHTAG_REGEX, '').strip
  end

  # Scope to get visible posts for a specific user
  def self.visible_for(current_user)
    if current_user
      # Show: public posts + own posts + friends_only posts from followed users
      where(privacy: :public_post)
        .or(where(user_id: current_user.id))
        .or(where(privacy: :friends_only, user_id: current_user.following.select(:id)))
    else
      # Not logged in: only public posts
      where(privacy: :public_post)
    end
  end

  PRIVACY_ICONS = {
    'public_post' => '🌐',
    'friends_only' => '👥',
    'only_me' => '🔒'
  }.freeze

  def privacy_icon
    PRIVACY_ICONS[privacy]
  end

  PRIVACY_LABELS = {
    'public_post' => 'Public',
    'friends_only' => 'Friends',
    'only_me' => 'Only Me'
  }.freeze

  def privacy_label
    PRIVACY_LABELS[privacy]
  end

  private

  def extract_and_save_hashtags
    hashtags.clear

    content.scan(HASHTAG_REGEX).each do |tag|
      hashtag = Hashtag.find_or_create_by!(name: tag.delete('#'))
      hashtags << hashtag
    end
  end

  def index_to_solr
    SolrClient.add(
      id: id,
      content: content,
      content_txt: content,
      content_suggest: content,
      user_id: user_id,
      created_at: created_at.iso8601,
      hashtags: hashtags.pluck(:name)
    )
  end

  def remove_from_solr
    SolrClient.connection.delete_by_id(id)
    SolrClient.connection.commit
  end

  def extract_and_notify_mentions
    mentioned_usernames = extract_mentions

    mentioned_usernames.each do |username|
      # Try to find user by email prefix (before @) or by name without spaces
      mentioned_user = User.find_by("LOWER(REPLACE(name, ' ', '')) = ?", username.downcase) ||
                       User.find_by("LOWER(SUBSTRING_INDEX(email, '@', 1)) = ?", username.downcase)

      if mentioned_user && mentioned_user.id != user_id
        NotificationService.create_mention_notification(user, mentioned_user, self)
      end
    end
  end
end
