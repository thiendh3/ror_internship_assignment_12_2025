class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :micropost
  
  validates :content, presence: true, length: { maximum: 1000 }
  validates :user_id, presence: true
  validates :micropost_id, presence: true
  
  default_scope -> { order(created_at: :asc) }
end
