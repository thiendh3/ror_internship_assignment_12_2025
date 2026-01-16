class Like < ApplicationRecord
  belongs_to :user
  belongs_to :micropost

  enum :reaction_type, { like: 0, love: 1, haha: 2 }

  validates :user_id, uniqueness: { scope: :micropost_id }
  validates :reaction_type, presence: true
end
