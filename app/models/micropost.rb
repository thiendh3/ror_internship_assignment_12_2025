class Micropost < ApplicationRecord
  # Searchkick for Elasticsearch full-text search
  searchkick word_start: [:content]
  
  belongs_to :user
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

  # Define searchable data for Searchkick
  def search_data
    {
      content: content,
      user_id: user_id,
      user_name: user.name,
      created_at: created_at
    }
  end
end
