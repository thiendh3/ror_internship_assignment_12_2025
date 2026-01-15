class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :micropost

  validates :content, presence: true, length: { maximum: 1000 }

  default_scope -> { order(created_at: :asc) }
end
