class Micropost < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  default_scope -> { order(created_at: :desc)}
  validates :user_id, presence: true
  validates :content, presence: true, length: {maximum: 140}
  validates :image, content_type: { in: %w[image/jpeg image/gif image/png],
                                    message: "must be a valid image format"},
                    size:{ less_than: 5.megabytes,
                            message: "should be less than 5MB"}

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
  after_commit :reindex, on: [:create, :update]
  
  # Reindex when micropost is destroyed
  after_commit :remove_from_index, on: :destroy

                            
  #Return a resized image for display
  def display_image
    image.variant(resize_to_limit: [500, 500])
  end

  private
  # Reindex micropost to Solr
  def reindex
    Sunspot.index(self)
  end
  
  # Remove micropost from Solr index
  def remove_from_index
    Sunspot.remove(self)
  end
end
