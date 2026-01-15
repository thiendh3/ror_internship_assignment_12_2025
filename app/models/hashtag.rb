class Hashtag < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  has_many :micropost_hashtags, dependent: :destroy
  has_many :microposts, through: :micropost_hashtags
end
