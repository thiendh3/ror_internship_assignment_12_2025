class Micropost < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_many :versions, class_name: 'MicropostVersion', dependent: :destroy

  before_update :save_version
  default_scope -> { order(created_at: :desc) }
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
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
end
