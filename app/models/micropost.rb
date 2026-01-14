class Micropost < ApplicationRecord
  after_save :extract_and_save_hashtags
  after_commit :index_to_solr
  after_destroy :remove_from_solr

  belongs_to :user

  has_many :micropost_hashtags, dependent: :destroy
  has_many :hashtags, through: :micropost_hashtags

  has_one_attached :image
  default_scope -> { order(created_at: :desc)}
  validates :user_id, presence: true
  validates :content, presence: true, length: {maximum: 140}
  validates :image, content_type: { in: %w[image/jpeg image/gif image/png],
                                    message: "must be a valid image format"},
                    size:{ less_than: 5.megabytes,
                            message: "should be less than 5MB"}

  #Return a resized image for display
  def display_image
    image.variant(resize_to_limit: [500, 500])
  end

  def display_image_url
    return nil unless image.attached?
    Rails.application.routes.url_helpers.rails_blob_path(display_image, only_path: true)
  end

  HASHTAG_REGEX = /#\w+/

  def extract_hashtags
    content.scan(HASHTAG_REGEX).map(&:downcase).uniq
  end

  private
    def extract_and_save_hashtags
      hashtags.clear

      content.scan(HASHTAG_REGEX).each do |tag|
        hashtag = Hashtag.find_or_create_by!(name: tag.delete('#'))
        self.hashtags << hashtag
      end
    end

    def index_to_solr
      SolrClient.add(
        id: id,
        content: content,
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
end

