class Hashtag < ApplicationRecord
  has_many :micropost_hashtags, dependent: :destroy
  has_many :microposts, through: :micropost_hashtags

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  
  before_validation :normalize_name

  private

  def normalize_name
    self.name = name.downcase.strip if name.present?
  end
end
